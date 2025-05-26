// lib/src/models/appointment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String professionalId;
  final DateTime date;
  final String status;
  final String? details;

  Appointment({
    required this.id,
    required this.patientId,
    required this.professionalId,
    required this.date,
    required this.status,
    this.details,
  });

  // Método factory para crear una instancia de Appointment desde un DocumentSnapshot
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientId: data['patient_id'] ?? '',
      professionalId: data['professional_id'] ?? '',
      date: (data['date'] as Timestamp).toDate(), // Convertir Timestamp a DateTime
      status: data['status'] ?? 'pending',
      details: data['details'],
    );
  }

  // Método para convertir una instancia de Appointment a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'professional_id': professionalId,
      'date': Timestamp.fromDate(date), // Convertir DateTime a Timestamp
      'status': status,
      'details': details,
    };
  }
}
