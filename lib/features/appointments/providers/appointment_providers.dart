// lib/features/appointments/providers/appointment_providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/appointment_service.dart';
import '../models/appointment.dart';
import '/features/auth/providers/session_provider.dart';

/// Provider for the appointment service
final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService();
});

/// Provider for patient appointments
final patientAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  final service = ref.watch(appointmentServiceProvider);
  final userId = ref.watch(userIdProvider);
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return service.getAppointmentsByPatient(userId).map((snapshot) {
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
  });
});

/// Provider for professional appointments
final professionalAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  final service = ref.watch(appointmentServiceProvider);
  final userId = ref.watch(userIdProvider);
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return service.getAppointmentsByProfessional(userId).map((snapshot) {
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
  });
});

/// Provider for appointment filters
final appointmentFilterProvider = StateProvider<String>((ref) => 'all');

/// Provider for filtered appointments
final filteredAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final appointments = ref.watch(patientAppointmentsProvider);
  final filter = ref.watch(appointmentFilterProvider);
  
  return appointments.when(
    data: (data) {
      if (filter == 'all') return data;
      return data.where((appointment) => appointment.status == filter).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});