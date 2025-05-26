import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Citas'),
          backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        ),
        body: Center(
          child: Text('No se encontró el usuario autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Citas'),
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No hay citas disponibles'),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text('Cita con ${appointment['professionalName']}'),
                  subtitle: Text('Fecha: ${appointment['date']}'),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    // Navegar a los detalles de la cita
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetailsScreen(
                          appointmentId: appointment.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;

  AppointmentDetailsScreen({required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la Cita'),
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('No se encontraron detalles para esta cita'),
            );
          }

          final appointment = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cita con ${appointment['professionalName']}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Fecha: ${appointment['date']}'),
                SizedBox(height: 10),
                Text('Hora: ${appointment['time']}'),
                SizedBox(height: 10),
                Text('Ubicación: ${appointment['location']}'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Lógica para cancelar la cita
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('Cancelar Cita'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
