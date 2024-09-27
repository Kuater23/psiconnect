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
          title: Text('Agenda Digital'),
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

    // Si el ID del paciente no es nulo, mostrar la lista de profesionales
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda Digital'),
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
            return Center(child: Text('No hay profesionales disponibles'));
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
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${professional['lastName']}, ${professional['name']}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Clinica medica',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text('${professional['address']}'),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.email),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text('${professional['email']}'),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.phone),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text('${professional['phone']}'),
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
                          icon: Icon(Icons.arrow_forward),
                          label: Text('Ver agenda'),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos de contacto:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 5),
                Expanded(
                  child: Text('${professional['address']}'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.email),
                SizedBox(width: 5),
                Expanded(
                  child: Text('${professional['email']}'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.phone),
                SizedBox(width: 5),
                Expanded(
                  child: Text('${professional['phone']}'),
                ),
              ],
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
