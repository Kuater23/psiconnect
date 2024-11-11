import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Importa el SharedDrawer

class MySessionsPatientPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Sesiones'),
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
      ),
      drawer: SharedDrawer(), // Añade el SharedDrawer
      body: user == null
          ? Center(child: Text('No estás autenticado'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('patientId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar las sesiones'));
                }

                final sessions = snapshot.data?.docs ?? [];

                if (sessions.isEmpty) {
                  return Center(child: Text('No tienes sesiones reservadas'));
                }

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session =
                        sessions[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('Profesional: ${session['professionalId']}'),
                      subtitle: Text(
                          'Día: ${session['day']} - Hora: ${session['time']}'),
                    );
                  },
                );
              },
            ),
    );
  }
}
