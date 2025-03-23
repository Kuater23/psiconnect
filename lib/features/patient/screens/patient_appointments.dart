import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Asegúrate de importar la página de solicitud si deseas navegar entre ellas.
import 'patient_book_schedule.dart';

class PatientAppointments extends StatelessWidget {
  // Simulamos el id del paciente actual. Reemplázalo por la lógica de autenticación.
  final String currentPatientId = 'patient123';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Citas'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('Menú',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Solicitar Cita'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PatientBookSchedule()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Mis Citas'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: currentPatientId)
            .orderBy('appointmentDateTime', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text('No tienes citas programadas'));

          final appointments = snapshot.data!.docs;
          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment =
                  appointments[index].data() as Map<String, dynamic>;
              Timestamp timestamp = appointment['appointmentDateTime'];
              DateTime dateTime = timestamp.toDate();
              String formattedDate =
                  DateFormat('EEEE, MMM d, y').format(dateTime);
              String formattedTime = DateFormat('HH:mm').format(dateTime);
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text(appointment['doctorName'] ?? 'Doctor'),
                  subtitle:
                      Text('$formattedDate a las $formattedTime'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
