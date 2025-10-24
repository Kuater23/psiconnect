// lib/features/appointments/services/appointment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../repositories/appointment_repository.dart';
import 'doctor_patient_service.dart';
import '../../../core/services/error_logger.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final _repository = AppointmentRepository();
  final _doctorPatientService = DoctorPatientService();
  final _firestore = FirebaseFirestore.instance;

  // ==================== CRUD Operations ====================

  /// Crear cita con relación doctor-paciente atómica
  Future<String> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime scheduledAt,
    String? patientName,
    String? doctorName,
    String? doctorSpeciality,
    String? details,
    bool isVirtual = false,
    String? location,
    String? meetingLink,
  }) async {
    try {
      // Validar que el horario esté disponible
      final isAvailable = await _repository.isTimeSlotAvailable(
        doctorId: doctorId,
        scheduledAt: scheduledAt,
      );

      if (!isAvailable) {
        throw Exception('El horario seleccionado no está disponible');
      }

      final appointment = Appointment(
        patientId: patientId,
        doctorId: doctorId,
        patientName: patientName,
        doctorName: doctorName,
        doctorSpeciality: doctorSpeciality,
        scheduledAt: scheduledAt,
        details: details,
        isVirtual: isVirtual,
        location: location,
        meetingLink: meetingLink,
        status: 'scheduled',
      );

      final appointmentId = await _firestore.runTransaction((tx) async {
        // 1. Crear la cita
        final ref = _firestore.collection('appointments').doc();
        tx.set(ref, appointment.toMap());

        // 2. Crear/actualizar relación doctor-paciente
        final relationId = '${doctorId}_$patientId';
        final relRef = _firestore.collection('doctor_patients').doc(relationId);
        final snap = await tx.get(relRef);

        if (snap.exists) {
          tx.update(relRef, {
            'lastUpdated': FieldValue.serverTimestamp(),
            'updateCount': FieldValue.increment(1),
            'lastUpdateSource': 'appointment_service',
            'status': 'active',
          });
        } else {
          tx.set(relRef, {
            'doctorId': doctorId,
            'patientId': patientId,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'status': 'active',
            'updateCount': 1,
            'source': 'appointment_service',
          });
        }

        return ref.id;
      });

      ErrorLogger.info('Cita creada exitosamente', {'appointmentId': appointmentId});
      return appointmentId;
    } catch (e, st) {
      ErrorLogger.logError('Error creando cita', e, st, additionalData: {
        'patientId': patientId,
        'doctorId': doctorId,
        'scheduledAt': scheduledAt.toIso8601String(),
      });
      rethrow;
    }
  }

  Future<Appointment?> getAppointment(String id) async {
    try {
      return await _repository.read(id);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo cita', e, st);
      rethrow;
    }
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      await _repository.update(id, data);
    } catch (e, st) {
      ErrorLogger.logError('Error actualizando cita', e, st);
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await _repository.delete(id);
    } catch (e, st) {
      ErrorLogger.logError('Error eliminando cita', e, st);
      rethrow;
    }
  }

  // ==================== Métodos de Negocio ====================

  Future<List<Appointment>> getPatientAppointments(String patientId) async {
    try {
      return await _repository.getByPatient(patientId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo citas del paciente', e, st);
      rethrow;
    }
  }

  Stream<List<Appointment>> streamPatientAppointments(String patientId) {
    return _repository.streamByPatient(patientId);
  }

  Future<List<Appointment>> getDoctorAppointments(String doctorId) async {
    try {
      return await _repository.getByDoctor(doctorId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo citas del doctor', e, st);
      rethrow;
    }
  }

  Stream<List<Appointment>> streamDoctorAppointments(String doctorId) {
    return _repository.streamByDoctor(doctorId);
  }

  Future<List<Appointment>> getScheduledByPatient(String patientId) async {
    try {
      return await _repository.getScheduledByPatient(patientId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo citas programadas del paciente', e, st);
      rethrow;
    }
  }

  Stream<List<Appointment>> streamScheduledByPatient(String patientId) {
    return _repository.streamScheduledByPatient(patientId);
  }

  Future<List<Appointment>> getScheduledByDoctor(String doctorId) async {
    try {
      return await _repository.getScheduledByDoctor(doctorId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo citas programadas del doctor', e, st);
      rethrow;
    }
  }

  Stream<List<Appointment>> streamScheduledByDoctor(String doctorId) {
    return _repository.streamScheduledByDoctor(doctorId);
  }

  Future<List<Appointment>> getTodayAppointmentsByDoctor(String doctorId) async {
    try {
      return await _repository.getTodayByDoctor(doctorId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo citas del día', e, st);
      rethrow;
    }
  }

  Future<List<Appointment>> getUpcomingByPatient(String patientId, {int days = 7}) async {
    try {
      return await _repository.getUpcomingByPatient(patientId, days: days);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo próximas citas del paciente', e, st);
      rethrow;
    }
  }

  Future<List<Appointment>> getUpcomingByDoctor(String doctorId, {int days = 7}) async {
    try {
      return await _repository.getUpcomingByDoctor(doctorId, days: days);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo próximas citas del doctor', e, st);
      rethrow;
    }
  }

  Future<bool> isTimeSlotAvailable({
    required String doctorId,
    required DateTime scheduledAt,
    String? excludeAppointmentId,
  }) async {
    try {
      return await _repository.isTimeSlotAvailable(
        doctorId: doctorId,
        scheduledAt: scheduledAt,
        excludeAppointmentId: excludeAppointmentId,
      );
    } catch (e, st) {
      ErrorLogger.logError('Error verificando disponibilidad', e, st);
      return false;
    }
  }

  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _repository.cancelAppointment(appointmentId, reason);
      ErrorLogger.info('Cita cancelada', {'appointmentId': appointmentId, 'reason': reason});
    } catch (e, st) {
      ErrorLogger.logError('Error cancelando cita', e, st);
      rethrow;
    }
  }

  Future<void> completeAppointment(String appointmentId, {String? notes}) async {
    try {
      await _repository.completeAppointment(appointmentId, notes: notes);
      ErrorLogger.info('Cita completada', {'appointmentId': appointmentId});
    } catch (e, st) {
      ErrorLogger.logError('Error completando cita', e, st);
      rethrow;
    }
  }

  Future<void> rescheduleAppointment(String appointmentId, DateTime newScheduledAt) async {
    try {
      final appointment = await _repository.read(appointmentId);
      if (appointment == null) {
        throw Exception('Cita no encontrada');
      }

      final isAvailable = await _repository.isTimeSlotAvailable(
        doctorId: appointment.doctorId,
        scheduledAt: newScheduledAt,
        excludeAppointmentId: appointmentId,
      );

      if (!isAvailable) {
        throw Exception('El nuevo horario no está disponible');
      }

      await _repository.rescheduleAppointment(appointmentId, newScheduledAt);
      ErrorLogger.info('Cita reagendada', {
        'appointmentId': appointmentId,
        'newScheduledAt': newScheduledAt.toIso8601String(),
      });
    } catch (e, st) {
      ErrorLogger.logError('Error reagendando cita', e, st);
      rethrow;
    }
  }

  Future<Map<String, int>> getDoctorStats(String doctorId) async {
    try {
      return await _repository.getDoctorStats(doctorId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo estadísticas del doctor', e, st);
      return {};
    }
  }

  Future<Map<String, int>> getPatientStats(String patientId) async {
    try {
      return await _repository.getPatientStats(patientId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo estadísticas del paciente', e, st);
      return {};
    }
  }

  // ==================== Validaciones ====================

  String? validateAppointmentData({
    required String patientId,
    required String doctorId,
    required DateTime scheduledAt,
    bool isVirtual = false,
    String? location,
    String? meetingLink,
  }) {
    if (patientId.isEmpty) {
      return 'ID de paciente requerido';
    }

    if (doctorId.isEmpty) {
      return 'ID de doctor requerido';
    }

    if (scheduledAt.isBefore(DateTime.now())) {
      return 'La fecha debe ser futura';
    }

    if (isVirtual && (meetingLink == null || meetingLink.isEmpty)) {
      return 'Link de reunión requerido para citas virtuales';
    }

    if (!isVirtual && (location == null || location.isEmpty)) {
      return 'Ubicación requerida para citas presenciales';
    }

    return null;
  }
}