import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener citas filtradas por el paciente
  Stream<QuerySnapshot> getAppointmentsByPatient(String patientId) {
    return _firestore
        .collection('appointments')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('date')
        .snapshots();
  }

  // Obtener citas filtradas por el profesional
  Stream<QuerySnapshot> getAppointmentsByProfessional(String professionalId) {
    return _firestore
        .collection('appointments')
        .where('professional_id', isEqualTo: professionalId)
        .orderBy('date')
        .snapshots();
  }

  // Crear una nueva cita
  Future<void> createAppointment(String patientId, String professionalId,
      DateTime date, String details) async {
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
      print("Error al crear cita: $e");
      throw Exception("Error al crear la cita: $e");
    }
  }

  // Actualizar estado de la cita
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
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
}
