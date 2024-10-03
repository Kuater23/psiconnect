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
        backgroundColor: Color.fromRGBO(
            2, 60, 67, 1), // Color base de Psiconnect para el fondo
        appBar: AppBar(
          title: Text('Agenda Digital'),
          backgroundColor: Color.fromRGBO(
              2, 60, 67, 1), // Color base de Psiconnect para el fondo
          titleTextStyle: TextStyle(
            color: Colors.white, // Color de texto blanco
            fontSize: 24, // Tamaño del texto
            fontWeight: FontWeight.bold, // Negrita para el texto
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
        drawer: SharedDrawer(), // Utilizar el Drawer compartido
        body: Center(
          child: Text(
            'No se encontró el paciente autenticado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Si el ID del paciente no es nulo, mostrar la lista de profesionales
    return Scaffold(
      backgroundColor: Color.fromRGBO(
          2, 60, 67, 1), // Color base de Psiconnect para el fondo
      appBar: AppBar(
        title: Text('Agenda Digital'),
        backgroundColor: Color.fromRGBO(
            2, 60, 67, 1), // Color base de Psiconnect para el fondo
        titleTextStyle: TextStyle(
          color: Colors.white, // Color de texto blanco
          fontSize: 24, // Tamaño del texto
          fontWeight: FontWeight.bold, // Negrita para el texto
        ),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'professional')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No hay profesionales disponibles',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final professionals = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              return Card(
                color: Color.fromRGBO(
                    1, 40, 45, 1), // Color de fondo del contenedor del login
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${professional['lastName']}, ${professional['name']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Clinica medica',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${professional['address']}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.white),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${professional['email']}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.white),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${professional['phone']}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfessionalAgenda(
                                  professional: professional,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(
                                11, 191, 205, 1), // Color de fondo del botón
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 10, // Aumentar la sombra para el botón
                          ),
                          icon: Icon(Icons.arrow_forward_ios,
                              color: Colors.white),
                          label: Text(
                            'Ver Agenda',
                            style: TextStyle(
                              color: Colors.white, // Color del texto
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProfessionalAgenda extends StatelessWidget {
  final QueryDocumentSnapshot professional;

  ProfessionalAgenda({required this.professional});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(
          2, 60, 67, 1), // Color base de Psiconnect para el fondo
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Agenda del Dr. ${professional['lastName']}, ${professional['name']}',
        ),
        backgroundColor: Color.fromRGBO(
            2, 60, 67, 1), // Color base de Psiconnect para el fondo
        titleTextStyle: TextStyle(
          color: Colors.white, // Color de texto blanco
          fontSize: 24, // Tamaño del texto
          fontWeight: FontWeight.bold, // Negrita para el texto
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Color.fromRGBO(
              1, 40, 45, 1), // Color de fondo del contenedor del login
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos de contacto:',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${professional['address']}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.white),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${professional['email']}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.white),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${professional['phone']}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
