import 'package:Psiconnect/src/screens/professional/professional_files.dart';
import 'package:Psiconnect/src/service/professional_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha

class ProfessionalAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Obtener el ID del profesional autenticado
    final String? professionalId = FirebaseAuth.instance.currentUser?.uid;

    // Verificar que el ID del profesional no sea nulo
    if (professionalId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Citas Profesionales'),
        ),
        body: Center(child: Text('No se encontró el profesional autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Citas Profesionales'),
      ),
      body: StreamBuilder(
        stream: AppointmentService().getAppointmentsByProfessional(professionalId),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No tienes citas programadas.'));
          }

          // Mapa para agrupar las citas por paciente
          Map<String, List<QueryDocumentSnapshot>> groupedAppointments = {};

          // Agrupar citas por paciente
          for (var appointment in snapshot.data!.docs) {
            String patientId = appointment['patient_id'];
            if (!groupedAppointments.containsKey(patientId)) {
              groupedAppointments[patientId] = [];
            }
            groupedAppointments[patientId]!.add(appointment);
          }

          // Crear una lista expandible para cada paciente y sus citas
          return ListView(
            children: groupedAppointments.entries.map((entry) {
              String patientId = entry.key;
              List<QueryDocumentSnapshot> patientAppointments = entry.value;

              return ExpansionTile(
                title: Text('Paciente ID: $patientId'),
                children: patientAppointments.map((appointment) {
                  // Convertir y formatear la fecha de la cita
                  DateTime appointmentDate = DateTime.parse(appointment['date']);
                  String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(appointmentDate);

                  return Card(
                    child: ListTile(
                      title: Text('Fecha: $formattedDate'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado: ${appointment['status']}'),
                          Text('Detalles: ${appointment['details'] ?? "Sin detalles"}'),
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
                              patientId: appointment['patient_id'],
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
  final String patientId;

  AppointmentDetails({required this.appointmentId, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la Cita'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cita ID: $appointmentId'),
            Text('Paciente ID: $patientId'),
            // Aquí puedes agregar más detalles de la cita si lo deseas
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfessionalFiles(patientId: patientId),
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
