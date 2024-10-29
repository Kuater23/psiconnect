import 'package:flutter/material.dart';
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

  // Crear una nueva cita (opcional, para añadir citas manualmente)
  Future<void> createAppointment(String patientId, String professionalId,
      DateTime date, String details) async {
    try {
      await _firestore.collection('appointments').add({
        'patient_id': patientId,
        'professional_id': professionalId,
        'date': date.toIso8601String(),
        'status': 'pending', // Estado inicial de la cita
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error al crear cita: $e");
    }
  }

  // Actualizar estado de la cita (pendiente, confirmada, cancelada)
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
      });
    } catch (e) {
      print("Error al actualizar estado de la cita: $e");
    }
  }
}

class PatientServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(2, 60, 67, 1), // Color de fondo
      appBar: AppBar(
        title: Text('Patient Service'),
        backgroundColor:
            Color.fromRGBO(2, 60, 67, 1), // Color de fondo del AppBar
      ),
      body: Center(
        child: Text(
          'Contenido del Patient Service',
          style: TextStyle(color: Colors.white), // Color del texto
        ),
      ),
    );
  }
}
