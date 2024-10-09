import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService();
});

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener citas filtradas por el ID del profesional
  Stream<QuerySnapshot> getAppointmentsByProfessional(String professionalId) {
    return _firestore
        .collection('appointments')
        .where('professional_id', isEqualTo: professionalId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Obtener citas filtradas por el ID del paciente
  Stream<QuerySnapshot> getAppointmentsByPatient(String patientId) {
    return _firestore
        .collection('appointments')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('date', descending: true)
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
        'details': details,
        'status': 'pending', // Estado inicial de la cita
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error al crear cita: $e");
      throw Exception('Error al crear la cita.');
    }
  }

  // Actualizar el estado de una cita
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
      });
    } catch (e) {
      print("Error al actualizar el estado de la cita: $e");
      throw Exception('Error al actualizar el estado de la cita.');
    }
  }

  // Obtener los detalles de una cita específica
  Future<DocumentSnapshot> getAppointmentDetails(String appointmentId) async {
    try {
      return await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
    } catch (e) {
      print("Error al obtener detalles de la cita: $e");
      throw Exception('Error al obtener los detalles de la cita.');
    }
  }

  // Cancelar una cita
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      print("Error al cancelar la cita: $e");
      throw Exception('Error al cancelar la cita.');
    }
  }
}
