// lib/src/models/appointment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String date;
  final String status;
  final String? details;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.status,
    this.details,
  });

  // Método factory para crear una instancia de Appointment desde un DocumentSnapshot
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      date: data['date'] ?? '',
      status: data['status'] ?? 'pending',
      details: data['details'],
    );
  }

  // Otros métodos, si es necesario...
}
