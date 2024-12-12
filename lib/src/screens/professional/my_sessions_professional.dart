import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Importa el SharedDrawer

class MySessionsProfessionalPage extends StatelessWidget {
  final VoidCallback toggleTheme;

  MySessionsProfessionalPage({required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Fondo según el tema
      appBar: AppBar(
        title: Text('Mis Sesiones'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Color.fromRGBO(
                2, 60, 67, 1), // Color base de Psiconnect para el fondo
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(toggleTheme: toggleTheme), // Añade el SharedDrawer
      body: user == null
          ? Center(child: Text('No estás autenticado'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('professionalId', isEqualTo: user.uid)
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
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(session['patientId'])
                          .get(),
                      builder: (context, patientSnapshot) {
                        if (patientSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (patientSnapshot.hasError ||
                            !patientSnapshot.hasData) {
                          return Center(
                              child: Text(
                                  'Error al cargar los datos del paciente'));
                        }

                        final patientData = patientSnapshot.data!.data()
                            as Map<String, dynamic>;

                        return Card(
                          color: Theme.of(context)
                              .cardColor, // Color según el tema
                          margin: EdgeInsets.all(10),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paciente: ${patientData['name']} ${patientData['lastName']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color ??
                                        Colors
                                            .black, // Color del texto según el tema
                                  ),
                                ),
                                SizedBox(height: 10),
                                Divider(),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color:
                                            Theme.of(context).iconTheme.color),
                                    SizedBox(width: 10),
                                    Text(
                                      'Día y hora reservado: ${session['appointmentDay']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color ??
                                            Colors
                                                .black, // Color del texto según el tema
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.email,
                                        color:
                                            Theme.of(context).iconTheme.color),
                                    SizedBox(width: 10),
                                    Text(
                                      'Email: ${patientData['email']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color ??
                                            Colors
                                                .black, // Color del texto según el tema
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.phone,
                                        color:
                                            Theme.of(context).iconTheme.color),
                                    SizedBox(width: 10),
                                    Text(
                                      'Teléfono: ${patientData['phone']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color ??
                                            Colors
                                                .black, // Color del texto según el tema
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
