import 'package:Psiconnect/src/screens/patient/patient_files.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Psiconnect/src/providers/patient_appointments_provider.dart';

class PatientAppointments extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsState = ref.watch(patientAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda Digital'),
      ),
      drawer: SharedDrawer(),
      body: appointmentsState.when(
        loading: () => Center(child: CircularProgressIndicator()),
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(child: Text('No tienes citas programadas.'));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              DateTime appointmentDate = DateTime.parse(appointment.date);
              String formattedDate =
                  DateFormat('dd/MM/yyyy HH:mm').format(appointmentDate);

              // En el ListView.builder
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Fecha: $formattedDate'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado: ${appointment.status}'),
                      Text('Detalles: ${appointment.details}'),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetails(
                          appointmentId: appointment.id,
                          patientId: appointment.patientId,
                          professionalId: appointment.professionalId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
  final String professionalId; // Añade este campo

  AppointmentDetails({
    required this.appointmentId,
    required this.patientId,
    required this.professionalId, // Añade este parámetro requerido
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
            Text(
                'Profesional ID: $professionalId'), // Muestra el ID del profesional
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientFiles(
                      patientId: patientId,
                      professionalId: '',
                    ),
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
