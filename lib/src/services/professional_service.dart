import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener citas filtradas por el profesional
  Stream<QuerySnapshot> getAppointmentsByProfessional(String professionalId) {
    return _firestore
        .collection('appointments')
        .where('professional_id', isEqualTo: professionalId)
        .orderBy('date')
        .snapshots();
  }

  // Crear una nueva cita
  Future<void> createAppointment({
    required String patientId,
    required String professionalId,
    required DateTime date,
    required String details,
  }) async {
    try {
      await _firestore.collection('appointments').add({
        'patient_id': patientId,
        'professional_id': professionalId,
        'date': date.toIso8601String(),
        'status': 'pending',
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error al crear la cita: $e");
      throw Exception("Error al crear la cita: $e");
    }
  }

  // Actualizar el estado de una cita
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error al actualizar el estado de la cita: $e");
      throw Exception("Error al actualizar la cita: $e");
    }
  }

  // Eliminar una cita
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      print("Error al eliminar la cita: $e");
      throw Exception("Error al eliminar la cita: $e");
    }
  }

  // Obtener una cita específica por su ID
  Future<DocumentSnapshot> getAppointmentById(String appointmentId) async {
    try {
      return await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
    } catch (e) {
      throw Exception('Error al obtener la cita: $e');
    }
  }

  // Obtener todas las citas de un profesional dentro de un rango de fechas
  Future<List<QueryDocumentSnapshot>> getAppointmentsByDateRange(
      String professionalId, DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('appointments')
          .where('professional_id', isEqualTo: professionalId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw Exception("Error al obtener citas por rango de fecha: $e");
    }
  }
}
