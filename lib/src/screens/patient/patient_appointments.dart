import 'package:Psiconnect/src/screens/patient/patient_files.dart';
import 'package:Psiconnect/src/service/patient_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Drawer compartido

class PatientAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Obtener el ID del paciente autenticado
    final String? patientId = FirebaseAuth.instance.currentUser?.uid;

    // Verificar que el ID del paciente no sea nulo
    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Citas del Paciente'),
          actions: [
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                );
              },
            ),
          ],
        ),
        drawer: SharedDrawer(), // Utilizar el Drawer compartido
        body: Center(child: Text('No se encontró el paciente autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Citas del Paciente'),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            },
          ),
        ],
      ),
      drawer: SharedDrawer(), // Utilizar el Drawer compartido
      body: StreamBuilder(
        stream: AppointmentService().getAppointmentsByPatient(patientId),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No tienes citas programadas.'));
          }

          // Mapa para agrupar las citas por profesional
          Map<String, List<QueryDocumentSnapshot>> groupedAppointments = {};

          // Agrupar citas por profesional
          for (var appointment in snapshot.data!.docs) {
            String professionalId = appointment['professional_id'];
            if (!groupedAppointments.containsKey(professionalId)) {
              groupedAppointments[professionalId] = [];
            }
            groupedAppointments[professionalId]!.add(appointment);
          }

          // Crear una lista expandible para cada profesional y sus citas
          return ListView(
            children: groupedAppointments.entries.map((entry) {
              String professionalId = entry.key;
              List<QueryDocumentSnapshot> professionalAppointments =
                  entry.value;

              return ExpansionTile(
                title: Text('Profesional ID: $professionalId'),
                children: professionalAppointments.map((appointment) {
                  // Convertir y formatear la fecha de la cita
                  DateTime appointmentDate =
                      DateTime.parse(appointment['date']);
                  String formattedDate =
                      DateFormat('dd/MM/yyyy HH:mm').format(appointmentDate);

                  return Card(
                    child: ListTile(
                      title: Text('Fecha: $formattedDate'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado: ${appointment['status']}'),
                          Text(
                              'Detalles: ${appointment['details'] ?? "Sin detalles"}'),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navegar a los detalles de la cita
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetails(
                              appointmentId: appointment.id,
                              professionalId: appointment['professional_id'],
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
      ),
    );
  }
}

class AppointmentDetails extends StatelessWidget {
  final String appointmentId;
  final String professionalId;

  AppointmentDetails(
      {required this.appointmentId, required this.professionalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la Cita'),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            },
          ),
        ],
      ),
      drawer: SharedDrawer(), // Utilizar el Drawer compartido
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cita ID: $appointmentId'),
            Text('Profesional ID: $professionalId'),
            // Aquí puedes agregar más detalles de la cita si lo deseas
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PatientFiles(professionalId: professionalId),
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
