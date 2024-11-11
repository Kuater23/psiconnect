import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Reutiliza el menú hamburguesa
import 'package:intl/date_symbol_data_local.dart'; // Para inicializar la configuración regional
import 'package:Psiconnect/src/screens/patient/patient_book_schedule.dart'; // Importa la pantalla de agendar citas

class PatientAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? patientId = FirebaseAuth.instance.currentUser?.uid;

    if (patientId == null) {
      return Scaffold(
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        appBar: AppBar(
          title: Text('Agenda Digital'),
          backgroundColor: Color.fromRGBO(2, 60, 67, 1),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
        drawer: SharedDrawer(),
        body: Center(
          child: Text(
            'No se encontró el paciente autenticado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color.fromRGBO(2, 60, 67, 1),
      appBar: AppBar(
        title: Text('Agenda Digital'),
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ],
      ),
      drawer: SharedDrawer(),
      body: ProfessionalList(),
    );
  }
}

class ProfessionalList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'professional')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final professionals = snapshot.data!.docs;
        final totalProfessionals = professionals.length;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '$totalProfessionals resultados encontrados',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 10.0, // Espaciado horizontal entre tarjetas
                  runSpacing: 10.0, // Espaciado vertical entre tarjetas
                  children: professionals.map((professional) {
                    return Card(
                      color: Color.fromRGBO(2, 60, 67, 0.1), // Color más claro
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[100], // Color para diferenciar
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                              ),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Agenda Digital',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  Colors.green[100], // Color para diferenciar
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12.0),
                                bottomRight: Radius.circular(12.0),
                              ),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text(
                                      'Dr. ${professional['lastName']}, ${professional['name']}',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.black),
                                    SizedBox(width: 8),
                                    Text(
                                      professional['address'],
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.phone, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text(
                                      professional['phone'],
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  Colors.yellow[100], // Color para diferenciar
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12.0),
                                bottomRight: Radius.circular(12.0),
                              ),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  final args = {
                                    'lastName': professional['lastName'],
                                    'name': professional['name'],
                                  };
                                  Navigator.pushNamed(
                                    context,
                                    '/bookSchedule',
                                    arguments: args,
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Ver agenda',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    Icon(Icons.arrow_forward,
                                        color: Colors.black),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
