// lib/features/appointments/services/appointment_service.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '/core/exceptions/app_exception.dart';
import '/core/services/error_logger.dart';
import 'doctor_patient_service.dart';

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService();
});

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DoctorPatientService _doctorPatientService = DoctorPatientService();

  // Optimized cache settings for web
  AppointmentService() {
    if (kIsWeb) {
      _configureForWeb();
    }
  }

  void _configureForWeb() {
    _firestore.settings = const Settings(
      cacheSizeBytes: 40 * 1024 * 1024, // 40MB cache for appointments
      persistenceEnabled: true,
    );
  }

  // Get appointments filtered by professional with web optimizations
  Stream<QuerySnapshot> getAppointmentsByProfessional(String doctorId) {
    print('Buscando citas para doctor con ID: $doctorId');
    
    try {
      return _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId) // Asegúrate que este campo coincide exactamente con tu BD
          .orderBy('date', descending: true)
          .snapshots();
    } catch (e, stackTrace) {
      print('Error en consulta de Firebase: $e');
      ErrorLogger.logError(
        'Error getting professional appointments', 
        e, 
        stackTrace,
        additionalData: {'doctorId': doctorId}
      );
      rethrow;
    }
  }

  Stream<QuerySnapshot> getAppointmentsByPatient(String patientId) {
    try {
      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .snapshots();
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error getting patient appointments', 
        e, 
        stackTrace,
        additionalData: {'patientId': patientId}
      );
      rethrow;
    }
  }

  Future<String?> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime date,
    required String details,
    String? location,
    String? meetingLink,
    bool isVirtual = false,
  }) async {
    try {
      print('🔄 Creando cita: doctorId=$doctorId, patientId=$patientId');
      
      final appointmentData = {
        'patientId': patientId,
        'doctorId': doctorId,
        'date': date.toIso8601String(),
        'details': details,
        'status': 'pending',
        'isVirtual': isVirtual,
        'created_at': FieldValue.serverTimestamp(),
      };
      
      if (location != null) {
        appointmentData['location'] = location;
      }
      
      if (isVirtual && meetingLink != null) {
        appointmentData['meetingLink'] = meetingLink;
      }
      
      // Crear la cita
      final docRef = await _firestore.collection('appointments').add(appointmentData);
      
      print('✅ Cita creada con ID: ${docRef.id}');
      
      // IMPORTANTE: Crear relación doctor-paciente después de crear la cita
      await _doctorPatientService.createOrUpdateRelation(
        doctorId: doctorId,
        patientId: patientId,
        source: 'appointment_service',
      );
      
      return docRef.id;
    } catch (e) {
      print('❌ Error creando cita: $e');
      throw Exception('Error al crear la cita: ${e.toString()}');
    }
  }

  // Update appointment status with improved error handling
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      ErrorLogger.logEvent(
        'Appointment status updated',
        parameters: {'appointmentId': appointmentId, 'status': status}
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error updating appointment status', 
        e, 
        stackTrace,
        additionalData: {'appointmentId': appointmentId, 'status': status}
      );
      throw DataException('Error al actualizar el estado de la cita: ${e.toString()}');
    }
  }

  // Get appointment details with optimized caching
  Future<DocumentSnapshot> getAppointmentDetails(String appointmentId) async {
    try {
      return await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get(const GetOptions(source: Source.serverAndCache));
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error getting appointment details', 
        e, 
        stackTrace,
        additionalData: {'appointmentId': appointmentId}
      );
      throw DataException('Error al obtener los detalles de la cita: ${e.toString()}');
    }
  }

  // Cancel appointment with transaction to ensure consistency
  Future<void> cancelAppointment(String appointmentId, {String? cancelReason}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('appointments').doc(appointmentId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw DataException('La cita no existe');
        }
        
        transaction.update(docRef, {
          'status': 'cancelled',
          'cancelReason': cancelReason,
          'cancelled_at': FieldValue.serverTimestamp(),
        });
      });
      
      ErrorLogger.logEvent(
        'Appointment cancelled',
        parameters: {'appointmentId': appointmentId}
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error cancelling appointment', 
        e, 
        stackTrace,
        additionalData: {'appointmentId': appointmentId}
      );
      throw DataException('Error al cancelar la cita: ${e.toString()}');
    }
  }
  
  // Add patient notes to appointment
  Future<void> addPatientNotes(String appointmentId, String notes) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'patientNotes': notes,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error adding patient notes', 
        e, 
        stackTrace,
        additionalData: {'appointmentId': appointmentId}
      );
      throw DataException('Error al guardar las notas del paciente: ${e.toString()}');
    }
  }
  
  // Add professional notes to appointment
  Future<void> addProfessionalNotes(String appointmentId, String notes) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'professionalNotes': notes,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error adding professional notes', 
        e, 
        stackTrace,
        additionalData: {'appointmentId': appointmentId}
      );
      throw DataException('Error al guardar las notas del profesional: ${e.toString()}');
    }
  }
  
  // Get upcoming appointments for dashboard
  Future<List<QueryDocumentSnapshot>> getUpcomingAppointments(String userId, String role, {int limit = 5}) async {
    try {
      final now = DateTime.now().toIso8601String();
      final roleField = role == 'professional' ? 'doctorId' : 'patientId';
      
      final querySnapshot = await _firestore
          .collection('appointments')
          .where(roleField, isEqualTo: userId)
          .where('date', isGreaterThan: now)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('date')
          .limit(limit)
          .get();
          
      return querySnapshot.docs;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error getting upcoming appointments', 
        e, 
        stackTrace,
        additionalData: {'userId': userId, 'role': role}
      );
      throw DataException('Error al obtener las próximas citas: ${e.toString()}');
    }
  }
}