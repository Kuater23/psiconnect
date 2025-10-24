import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/error_logger.dart';

class DoctorPatientService {
  static final DoctorPatientService _instance = DoctorPatientService._internal();
  factory DoctorPatientService() => _instance;
  DoctorPatientService._internal();

  final _firestore = FirebaseFirestore.instance;

  /// Crear o actualizar relación doctor-paciente (usado fuera de transacciones)
  Future<void> createOrUpdateRelation({
    required String doctorId,
    required String patientId,
    String source = 'manual',
  }) async {
    if (doctorId.isEmpty || patientId.isEmpty) {
      ErrorLogger.info('IDs vacíos en createOrUpdateRelation');
      return;
    }

    final relationId = '${doctorId}_$patientId';
    final ref = _firestore.collection('doctor_patients').doc(relationId);

    try {
      final snap = await ref.get();
      
      if (snap.exists) {
        await ref.update({
          'lastUpdated': FieldValue.serverTimestamp(),
          'updateCount': FieldValue.increment(1),
          'lastUpdateSource': source,
          'status': 'active',
        });
      } else {
        await ref.set({
          'doctorId': doctorId,
          'patientId': patientId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'status': 'active',
          'updateCount': 1,
          'source': source,
        });
      }
      
      ErrorLogger.info('Relación doctor-paciente actualizada', {'relationId': relationId});
    } catch (e, st) {
      ErrorLogger.logError('Error en createOrUpdateRelation', e, st);
    }
  }

  /// Obtener pacientes de un doctor
  Future<List<String>> getDoctorPatients(String doctorId) async {
    try {
      final snap = await _firestore
          .collection('doctor_patients')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .get();
      
      return snap.docs.map((doc) => doc.data()['patientId'] as String).toList();
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo pacientes del doctor', e, st);
      return [];
    }
  }

  /// Obtener doctores de un paciente
  Future<List<String>> getPatientDoctors(String patientId) async {
    try {
      final snap = await _firestore
          .collection('doctor_patients')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'active')
          .get();
      
      return snap.docs.map((doc) => doc.data()['doctorId'] as String).toList();
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo doctores del paciente', e, st);
      return [];
    }
  }

  /// Desactivar relación (soft delete)
  Future<void> deactivateRelation(String doctorId, String patientId) async {
    try {
      final relationId = '${doctorId}_$patientId';
      await _firestore.collection('doctor_patients').doc(relationId).update({
        'status': 'inactive',
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      ErrorLogger.logError('Error desactivando relación', e, st);
      rethrow;
    }
  }
}