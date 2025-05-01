import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/services/error_logger.dart';

class DoctorPatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear o actualizar relación doctor-paciente
  Future<void> createOrUpdateRelation({
    required String doctorId,
    required String patientId,
    String? source,
  }) async {
    try {
      // Validación de entrada
      if (doctorId.isEmpty || patientId.isEmpty) {
        print('❌ Error: doctorId o patientId vacíos');
        return;
      }

      // ID del documento: doctorId_patientId
      final String relationId = '${doctorId}_${patientId}';
      
      // Debug para verificar
      print('⏳ Creando relación doctor-paciente: $relationId');
      
      // Verificar si existe el documento
      final docSnapshot = await _firestore
          .collection('doctor_patients')
          .doc(relationId)
          .get();
          
      if (docSnapshot.exists) {
        // Actualizar documento existente
        await _firestore
            .collection('doctor_patients')
            .doc(relationId)
            .update({
              'lastUpdated': FieldValue.serverTimestamp(),
              'updateCount': FieldValue.increment(1),
              'lastUpdateSource': source ?? 'update',
              'status': 'active', // Siempre activar la relación
            });
        print('✅ Relación doctor-paciente actualizada: $relationId');
      } else {
        // Crear nuevo documento
        await _firestore
            .collection('doctor_patients')
            .doc(relationId)
            .set({
              'doctorId': doctorId,
              'patientId': patientId,
              'createdAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
              'status': 'active',
              'updateCount': 1,
              'source': source ?? 'appointment'
            });
        print('✅ Nueva relación doctor-paciente creada: $relationId');
      }
    } catch (e) {
      print('❌ Error en doctor_patient_service: $e');
      try {
        ErrorLogger.logError('Error en doctor_patient_service', e, StackTrace.current);
      } catch (_) {
        // Ignore error logging errors
      }
    }
  }

  /// Obtener pacientes de un doctor específico
  Future<List<String>> getDoctorPatients(String doctorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctor_patients')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .get();
          
      return querySnapshot.docs
          .map((doc) => doc.data()['patientId'] as String)
          .toList();
    } catch (e) {
      print('Error obteniendo pacientes del doctor: $e');
      return [];
    }
  }

  /// Obtener doctores de un paciente específico
  Future<List<String>> getPatientDoctors(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctor_patients')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'active')
          .get();
          
      return querySnapshot.docs
          .map((doc) => doc.data()['doctorId'] as String)
          .toList();
    } catch (e) {
      print('Error obteniendo doctores del paciente: $e');
      return [];
    }
  }
}