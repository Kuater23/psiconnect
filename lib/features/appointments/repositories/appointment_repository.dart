import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/repositories/base_firestore_repository.dart';
import '../models/appointment.dart';

class AppointmentRepository extends BaseFirestoreRepository<Appointment> {
  static final AppointmentRepository _instance = AppointmentRepository._internal();
  factory AppointmentRepository() => _instance;
  AppointmentRepository._internal();

  @override
  String get collectionName => 'appointments';

  @override
  Appointment fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Appointment.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(Appointment item) {
    return item.toMap();
  }

  // ==================== Métodos Específicos de Citas ====================

  /// Obtener citas de un paciente
  Future<List<Appointment>> getByPatient(String patientId) async {
    return complexQuery(
      whereEquals: {'patientId': patientId},
      orderByField: 'scheduledAt',
      descending: true,
    );
  }

  /// Stream de citas de un paciente
  Stream<List<Appointment>> streamByPatient(String patientId) {
    return streamComplexQuery(
      whereEquals: {'patientId': patientId},
      orderByField: 'scheduledAt',
      descending: true,
    );
  }

  /// Obtener citas de un doctor
  Future<List<Appointment>> getByDoctor(String doctorId) async {
    return complexQuery(
      whereEquals: {'doctorId': doctorId},
      orderByField: 'scheduledAt',
      descending: true,
    );
  }

  /// Stream de citas de un doctor
  Stream<List<Appointment>> streamByDoctor(String doctorId) {
    return streamComplexQuery(
      whereEquals: {'doctorId': doctorId},
      orderByField: 'scheduledAt',
      descending: true,
    );
  }

  /// Obtener citas por estado
  Future<List<Appointment>> getByStatus(String status) async {
    return complexQuery(
      whereEquals: {'status': status},
      orderByField: 'scheduledAt',
      descending: true,
    );
  }

  /// Stream de citas por estado
  Stream<List<Appointment>> streamByStatus(String status) {
    return streamComplexQuery(
      whereEquals: {'status': status},
      orderByField: 'scheduledAt',
      descending: true,
    );
  }

  /// Obtener citas programadas de un paciente
  Future<List<Appointment>> getScheduledByPatient(String patientId) async {
    return complexQuery(
      whereEquals: {
        'patientId': patientId,
        'status': 'scheduled',
      },
      orderByField: 'scheduledAt',
      descending: false, // Próximas primero
    );
  }

  /// Stream de citas programadas de un paciente
  Stream<List<Appointment>> streamScheduledByPatient(String patientId) {
    return streamComplexQuery(
      whereEquals: {
        'patientId': patientId,
        'status': 'scheduled',
      },
      orderByField: 'scheduledAt',
      descending: false,
    );
  }

  /// Obtener citas programadas de un doctor
  Future<List<Appointment>> getScheduledByDoctor(String doctorId) async {
    return complexQuery(
      whereEquals: {
        'doctorId': doctorId,
        'status': 'scheduled',
      },
      orderByField: 'scheduledAt',
      descending: false,
    );
  }

  /// Stream de citas programadas de un doctor
  Stream<List<Appointment>> streamScheduledByDoctor(String doctorId) {
    return streamComplexQuery(
      whereEquals: {
        'doctorId': doctorId,
        'status': 'scheduled',
      },
      orderByField: 'scheduledAt',
      descending: false,
    );
  }

  /// Obtener citas del día para un doctor
  Future<List<Appointment>> getTodayByDoctor(String doctorId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('doctorId', isEqualTo: doctorId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('scheduledAt')
        .get();

    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtener próximas citas de un paciente (siguientes 7 días)
  Future<List<Appointment>> getUpcomingByPatient(String patientId, {int days = 7}) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('patientId', isEqualTo: patientId)
        .where('status', isEqualTo: 'scheduled')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
        .orderBy('scheduledAt')
        .get();

    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtener próximas citas de un doctor (siguientes 7 días)
  Future<List<Appointment>> getUpcomingByDoctor(String doctorId, {int days = 7}) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'scheduled')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
        .orderBy('scheduledAt')
        .get();

    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtener citas pasadas de un paciente
  Future<List<Appointment>> getPastByPatient(String patientId, {int limit = 20}) async {
    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('patientId', isEqualTo: patientId)
        .where('scheduledAt', isLessThan: Timestamp.fromDate(now))
        .orderBy('scheduledAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtener citas pasadas de un doctor
  Future<List<Appointment>> getPastByDoctor(String doctorId, {int limit = 20}) async {
    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('doctorId', isEqualTo: doctorId)
        .where('scheduledAt', isLessThan: Timestamp.fromDate(now))
        .orderBy('scheduledAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Verificar disponibilidad de horario para un doctor
  Future<bool> isTimeSlotAvailable({
    required String doctorId,
    required DateTime scheduledAt,
    String? excludeAppointmentId,
  }) async {
    // Ventana de 1 hora antes y después
    final startWindow = scheduledAt.subtract(const Duration(hours: 1));
    final endWindow = scheduledAt.add(const Duration(hours: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'scheduled')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startWindow))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(endWindow))
        .get();

    // Si hay que excluir una cita (para updates), filtrarla
    final conflicts = snapshot.docs.where((doc) {
      if (excludeAppointmentId != null && doc.id == excludeAppointmentId) {
        return false;
      }
      return true;
    }).toList();

    return conflicts.isEmpty;
  }

  /// Obtener citas entre dos fechas
  Future<List<Appointment>> getByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? doctorId,
    String? patientId,
  }) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(collectionName);

    if (doctorId != null) {
      query = query.where('doctorId', isEqualTo: doctorId);
    }

    if (patientId != null) {
      query = query.where('patientId', isEqualTo: patientId);
    }

    query = query
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('scheduledAt');

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtener estadísticas de citas de un doctor
  Future<Map<String, int>> getDoctorStats(String doctorId) async {
    final allAppointments = await getByDoctor(doctorId);

    return {
      'total': allAppointments.length,
      'scheduled': allAppointments.where((a) => a.status == 'scheduled').length,
      'completed': allAppointments.where((a) => a.status == 'completed').length,
      'cancelled': allAppointments.where((a) => a.status == 'cancelled').length,
      'pending': allAppointments.where((a) => a.status == 'pending').length,
      'virtual': allAppointments.where((a) => a.isVirtual).length,
      'inPerson': allAppointments.where((a) => !a.isVirtual).length,
    };
  }

  /// Obtener estadísticas de citas de un paciente
  Future<Map<String, int>> getPatientStats(String patientId) async {
    final allAppointments = await getByPatient(patientId);

    return {
      'total': allAppointments.length,
      'scheduled': allAppointments.where((a) => a.status == 'scheduled').length,
      'completed': allAppointments.where((a) => a.status == 'completed').length,
      'cancelled': allAppointments.where((a) => a.status == 'cancelled').length,
      'pending': allAppointments.where((a) => a.status == 'pending').length,
      'virtual': allAppointments.where((a) => a.isVirtual).length,
      'inPerson': allAppointments.where((a) => !a.isVirtual).length,
    };
  }

  /// Contar citas futuras de un doctor
  Future<int> countUpcomingByDoctor(String doctorId) async {
    final now = DateTime.now();

    return await FirebaseFirestore.instance
        .collection(collectionName)
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'scheduled')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .count()
        .get()
        .then((snapshot) => snapshot.count ?? 0);
  }

  /// Contar citas futuras de un paciente
  Future<int> countUpcomingByPatient(String patientId) async {
    final now = DateTime.now();

    return await FirebaseFirestore.instance
        .collection(collectionName)
        .where('patientId', isEqualTo: patientId)
        .where('status', isEqualTo: 'scheduled')
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .count()
        .get()
        .then((snapshot) => snapshot.count ?? 0);
  }

  /// Obtener última cita completada entre doctor y paciente
  Future<Appointment?> getLastCompletedAppointment({
    required String doctorId,
    required String patientId,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('doctorId', isEqualTo: doctorId)
        .where('patientId', isEqualTo: patientId)
        .where('status', isEqualTo: 'completed')
        .orderBy('scheduledAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return fromFirestore(snapshot.docs.first);
  }

  /// Cancelar cita con razón
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    await update(appointmentId, {
      'status': 'cancelled',
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Completar cita con notas opcionales
  Future<void> completeAppointment(String appointmentId, {String? notes}) async {
    final data = <String, dynamic>{
      'status': 'completed',
    };

    if (notes != null && notes.isNotEmpty) {
      data['notes'] = notes;
    }

    await update(appointmentId, data);
  }

  /// Reagendar cita
  Future<void> rescheduleAppointment(String appointmentId, DateTime newScheduledAt) async {
    await update(appointmentId, {
      'scheduledAt': Timestamp.fromDate(newScheduledAt),
      'status': 'scheduled', // Resetear a scheduled si estaba en otro estado
    });
  }
}