import 'package:Psiconnect/src/providers/session_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Psiconnect/src/models/appointment.dart';

final patientAppointmentsProvider =
    FutureProvider<List<Appointment>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) throw Exception("Sesión no encontrada");

  final snapshot = await FirebaseFirestore.instance
      .collection('appointments')
      .where('patient_id', isEqualTo: session.user.uid)
      .get();

  return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
});
