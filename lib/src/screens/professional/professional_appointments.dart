import 'package:Psiconnect/src/models/appointment.dart';
import 'package:Psiconnect/src/screens/professional/professional_files.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Psiconnect/src/providers/professional_appointments_provider.dart';

class ProfessionalAppointments extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsState = ref.watch(professionalAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Citas Profesionales'),
      ),
      drawer: SharedDrawer(),
      body: appointmentsState.when(
        loading: () => Center(child: CircularProgressIndicator()),
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(child: Text('No tienes citas programadas.'));
          }

          // Agrupar citas por paciente
          Map<String, List<Appointment>> groupedAppointments = {};
          for (var appointment in appointments) {
            groupedAppointments
                .putIfAbsent(appointment.patientId, () => [])
                .add(appointment);
          }

          return ListView(
            children: groupedAppointments.entries.map((entry) {
              String patientId = entry.key;
              List<Appointment> patientAppointments = entry.value;

              return ExpansionTile(
                title: Text('Paciente ID: $patientId'),
                children: patientAppointments.map((appointment) {
                  DateTime appointmentDate = DateTime.parse(appointment.date);
                  String formattedDate =
                      DateFormat('dd/MM/yyyy HH:mm').format(appointmentDate);

                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Fecha: $formattedDate'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado: ${appointment.status}'),
                          Text(
                              'Detalles: ${appointment.details ?? "Sin detalles"}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (newStatus) {
                          ref
                              .read(professionalAppointmentsProvider.notifier)
                              .updateAppointmentStatus(
                                appointment.id,
                                newStatus,
                              );
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'confirmed',
                            child: Text('Confirmar'),
                          ),
                          PopupMenuItem(
                            value: 'cancelled',
                            child: Text('Cancelar'),
                          ),
                          PopupMenuItem(
                            value: 'completed',
                            child: Text('Completar'),
                          ),
                        ],
                        icon: Icon(Icons.more_vert),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetails(
                              appointmentId: appointment.id,
                              patientId: appointment.patientId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
        error: (e, _) => Center(child: Text('Error al cargar citas: $e')),
      ),
    );
  }
}

class AppointmentDetails extends StatelessWidget {
  final String appointmentId;
  final String patientId;

  AppointmentDetails({
    required this.appointmentId,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la Cita'),
      ),
      drawer: SharedDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cita ID: $appointmentId'),
            Text('Paciente ID: $patientId'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfessionalFiles(patientId: patientId),
                  ),
                );
              },
              child: Text('Ver historial clínico completo'),
            ),
          ],
        ),
      ),
    );
  }
}
