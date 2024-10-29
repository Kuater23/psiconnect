import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/models/appointment.dart';
import 'package:Psiconnect/src/services/appointment_service.dart';
import 'package:Psiconnect/src/providers/session_provider.dart';

final professionalAppointmentsProvider = StateNotifierProvider<
    ProfessionalAppointmentsNotifier, AsyncValue<List<Appointment>>>((ref) {
  return ProfessionalAppointmentsNotifier(ref);
});

class ProfessionalAppointmentsNotifier
    extends StateNotifier<AsyncValue<List<Appointment>>> {
  final Ref _ref;

  ProfessionalAppointmentsNotifier(this._ref)
      : super(const AsyncValue.loading()) {
    _fetchProfessionalAppointments();
  }

  Future<void> _fetchProfessionalAppointments() async {
    final user = _ref.read(sessionProvider)?.user;
    if (user != null) {
      try {
        state = const AsyncValue.loading();
        final stream = _ref
            .read(appointmentServiceProvider)
            .getAppointmentsByProfessional(user.uid);
        stream.listen((snapshot) {
          final appointments = snapshot.docs.map((doc) {
            return Appointment.fromFirestore(doc);
          }).toList();
          state = AsyncValue.data(appointments);
        });
      } catch (e, stackTrace) {
        state = AsyncValue.error(
            'Error al cargar las citas del profesional.', stackTrace);
      }
    } else {
      state = AsyncValue.error('Usuario no autenticado.', StackTrace.current);
    }
  }

  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _ref.read(appointmentServiceProvider).updateAppointmentStatus(
            appointmentId,
            status,
          );
      _fetchProfessionalAppointments(); // Refresca la lista de citas después de actualizar el estado
    } catch (e, stackTrace) {
      state = AsyncValue.error(
          'Error al actualizar el estado de la cita.', stackTrace);
    }
  }
}
