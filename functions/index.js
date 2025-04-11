const admin = require("firebase-admin");
// Fix imports to use the correct paths
const functions = require("firebase-functions");
const logger = functions.logger;

// Initialize the application
admin.initializeApp();

/**
 * Función que limita la creación de usuarios por día
 * Previene ataques de registro masivo
 */
exports.limitUserCreation = functions.auth.user().onCreate((user) => {
  const db = admin.firestore();
  const today = new Date().toISOString().split("T")[0];
  const counterRef = db.collection("counters").doc("dailyUserCreation");

  return db.runTransaction(async (transaction) => {
    const doc = await transaction.get(counterRef);
    if (!doc.exists || doc.data().date !== today) {
      transaction.set(counterRef, {
        date: today,
        count: 1,
      });
    } else {
      const newCount = doc.data().count + 1;
      // Ajusta este valor según tus necesidades
      const DAILY_LIMIT = 40;

      if (newCount > DAILY_LIMIT) {
        await admin.auth().deleteUser(user.uid);
        throw new Error(
            "Daily user creation limit (" + DAILY_LIMIT + ") exceeded",
        );
      }
      transaction.update(counterRef, {count: newCount});
    }
  }).catch((error) => {
    logger.error("Error en limitación de usuarios:", error);
    return null;
  });
});

/**
 * Crea un perfil de usuario automáticamente después de la creación
 * de una cuenta de autenticación
 */
exports.createUserProfile = functions.auth.user().onCreate((user) => {
  const db = admin.firestore();

  // Si no hay datos de usuario o es un registro anónimo, salir
  if (!user || !user.email) return null;

  // Determinar colección basada en metadatos o datos adicionales
  let collectionName = "patients"; // Por defecto es paciente

  // Si existe un custom claim para el rol, usarlo
  if (user.customClaims && user.customClaims.role === "professional") {
    collectionName = "doctors";
  }

  // Crear documento de perfil básico
  return db.collection(collectionName).doc(user.uid).set({
    email: user.email,
    displayName: user.displayName || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    profileCompleted: false,
  });
});

/**
 * Envía notificaciones cuando se crea o actualiza una cita
 */
exports.handleAppointmentChanges = functions.firestore
    .document("appointments/{appointmentId}")
    .onUpdate(async (change, context) => {
      // Solamente ejecutar si hay cambios reales en los datos
      if (!change.before || !change.after) return null;

      const beforeData = change.before.data();
      const afterData = change.after.data();

      // Si el estado cambió, enviar notificaciones
      if (beforeData.status !== afterData.status) {
        const db = admin.firestore();

        // Obtener información del paciente y doctor
        const patientDoc = await db
            .collection("patients")
            .doc(afterData.patientId)
            .get();
        const doctorDoc = await db
            .collection("doctors")
            .doc(afterData.doctorId)
            .get();

        if (!patientDoc.exists || !doctorDoc.exists) {
          logger.error(
              "No se encontró el paciente o doctor para la cita:",
              context.params.appointmentId,
          );
          return null;
        }

        // Formatear fecha para las notificaciones
        const appointmentDate = new Date(afterData.date);
        const formattedDate = appointmentDate.toLocaleDateString("es-AR", {
          weekday: "long",
          day: "numeric",
          month: "long",
          hour: "2-digit",
          minute: "2-digit",
        });

        // Crear mensajes de notificación
        const patientName = `${patientDoc.data().firstName || ""} ${
          patientDoc.data().lastName || ""
        }`;
        const doctorName = `${doctorDoc.data().firstName || ""} ${
          doctorDoc.data().lastName || ""
        }`;

        // Guardar notificaciones en la colección "notifications"
        await db.collection("notifications").add({
          userId: afterData.patientId,
          title: `Estado de cita: ${afterData.status}`,
          message: `Tu cita con ${doctorName} para el ${formattedDate} ` +
            `ha sido ${afterData.status}`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await db.collection("notifications").add({
          userId: afterData.doctorId,
          title: `Estado de cita: ${afterData.status}`,
          message: `Tu cita con ${patientName} para el ${formattedDate} ` +
            `ha sido ${afterData.status}`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return null;
    });

/**
 * Recordatorio de citas programado diariamente
 */
exports.sendAppointmentReminders = functions.pubsub
    .schedule("0 8 * * *")  // Runs at 8:00 AM every day
    .onRun(async (context) => {
      const db = admin.firestore();
      const now = new Date();

      // Fecha para mañana
      const tomorrow = new Date();
      tomorrow.setDate(now.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);

      // Final del día de mañana
      const tomorrowEnd = new Date(tomorrow);
      tomorrowEnd.setHours(23, 59, 59, 999);

      // Buscar citas para mañana - usando Firestore Timestamp en lugar de ISO strings
      const appointments = await db.collection("appointments")
          .where("date", ">=", admin.firestore.Timestamp.fromDate(tomorrow))
          .where("date", "<=", admin.firestore.Timestamp.fromDate(tomorrowEnd))
          .where("status", "==", "confirmed")
          .get();

      // Enviar notificaciones para cada cita
      const batch = db.batch();

      appointments.docs.forEach((doc) => {
        const appointmentData = doc.data();

        // Crear notificación para el paciente
        const patientNotifRef = db.collection("notifications").doc();
        batch.set(patientNotifRef, {
          userId: appointmentData.patientId,
          title: "Recordatorio de cita",
          message: `Recuerda que mañana tienes una cita programada a las ${
            appointmentData.time
          }`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Crear notificación para el profesional
        const doctorNotifRef = db.collection("notifications").doc();
        batch.set(doctorNotifRef, {
          userId: appointmentData.doctorId,
          title: "Recordatorio de cita",
          message: `Recuerda que mañana tienes una cita programada a las ${
            appointmentData.time
          }`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Ejecutar todas las escrituras
      if (appointments.size > 0) {
        await batch.commit();
        logger.info(`Se enviaron ${appointments.size * 2} recordatorios de citas`);
      }

      return null;
    });

/**
 * Actualiza estadísticas de profesionales cuando se modifica una cita
 */
exports.updateDoctorStats = functions.firestore
    .document("appointments/{appointmentId}")
    .onCreate(async (snap, context) => {
      const appointment = snap.data();
      if (!appointment || !appointment.doctorId) return null;

      const db = admin.firestore();

      // Referencia al documento de estadísticas del doctor
      const statsRef = db.collection("doctorStats").doc(appointment.doctorId);

      // Actualizar estadísticas usando transacción para evitar sobreescrituras
      return db.runTransaction(async (transaction) => {
        const statsDoc = await transaction.get(statsRef);

        if (!statsDoc.exists) {
          // Crear documento inicial de estadísticas
          transaction.set(statsRef, {
            totalAppointments: 1,
            pendingAppointments: 1,
            completedAppointments: 0,
            cancelledAppointments: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          // Actualizar estadísticas existentes
          const stats = statsDoc.data();
          transaction.update(statsRef, {
            totalAppointments: stats.totalAppointments + 1,
            pendingAppointments: stats.pendingAppointments + 1,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });
    });

/**
 * Limpia datos de usuario cuando se elimina una cuenta
 */
exports.cleanupUserData = functions.auth.user().onDelete(async (user) => {
  const userId = user.uid;
  const db = admin.firestore();

  // Limpiar datos del usuario en varias colecciones usando batch
  const batch = db.batch();

  // Intentar eliminar de cada colección posible
  const collections = ["patients", "doctors", "admins"];

  for (const collection of collections) {
    const userDoc = db.collection(collection).doc(userId);
    batch.delete(userDoc);
  }

  // También podríamos buscar documentos relacionados como citas
  const appointmentsQuery = await db.collection("appointments")
      .where("patientId", "==", userId)
      .get();

  appointmentsQuery.docs.forEach((doc) => {
    batch.update(doc.ref, {
      status: "cancelled",
      notes: admin.firestore.FieldValue.arrayUnion(
          "Usuario eliminado automáticamente",
      ),
    });
  });

  // También podríamos manejar documentos donde el usuario era un profesional

  // Ejecutar el batch
  return batch.commit();
});