import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Reutiliza el menú hamburguesa
import 'package:intl/date_symbol_data_local.dart'; // Para inicializar la configuración regional
import 'package:Psiconnect/src/screens/patient/patient_book_schedule.dart'; // Importa la pantalla de agendar citas

class PatientAppointments extends StatefulWidget {
  final VoidCallback toggleTheme;

  PatientAppointments({required this.toggleTheme});

  @override
  _PatientAppointmentsState createState() => _PatientAppointmentsState();
}

class _PatientAppointmentsState extends State<PatientAppointments> {
  String? _selectedSpecialty;
  final List<String> _specialties = [
    'Todas',
    'Psicología Clínica',
    'Psicología Educativa',
    'Psicología Organizacional',
    'Psicología Social',
    'Psicología Forense'
  ]; // Lista de especialidades

  @override
  Widget build(BuildContext context) {
    final String? patientId = FirebaseAuth.instance.currentUser?.uid;

    if (patientId == null) {
      return Scaffold(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor, // Fondo según el tema
        appBar: AppBar(
          title: Text('Agenda Digital'),
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
              onPressed: widget.toggleTheme,
            ),
          ],
        ),
        drawer: SharedDrawer(toggleTheme: widget.toggleTheme),
        body: Center(
          child: Text(
            'No se encontró el paciente autenticado',
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black), // Color del texto según el tema
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Fondo según el tema
      appBar: AppBar(
        title: Text('Agenda Digital'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Color.fromRGBO(
                2, 60, 67, 1), // Color base de Psiconnect para el fondo
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(toggleTheme: widget.toggleTheme),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filtrar por Especialidad',
                filled: true,
                fillColor: Theme.of(context)
                    .inputDecorationTheme
                    .fillColor, // Color según el tema
              ),
              value: _selectedSpecialty,
              items: _specialties.map((String specialty) {
                return DropdownMenuItem<String>(
                  value: specialty,
                  child: Text(specialty),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSpecialty = value;
                });
              },
            ),
          ),
          Expanded(
              child: ProfessionalList(selectedSpecialty: _selectedSpecialty)),
        ],
      ),
    );
  }
}

class ProfessionalList extends StatelessWidget {
  final String? selectedSpecialty;

  ProfessionalList({this.selectedSpecialty});

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

        final professionals = snapshot.data!.docs.where((professional) {
          final data = professional.data() as Map<String, dynamic>;
          if (selectedSpecialty == null || selectedSpecialty == 'Todas') {
            return true;
          }
          return data.containsKey('specialty') &&
              data['specialty'] == selectedSpecialty;
        }).toList();

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
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.black, // Color del texto según el tema
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 10.0, // Espaciado horizontal entre tarjetas
                  runSpacing: 10.0, // Espaciado vertical entre tarjetas
                  children: professionals.map((professional) {
                    final data = professional.data() as Map<String, dynamic>;
                    return Card(
                      color: Theme.of(context).cardColor, // Color según el tema
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.1), // Color para diferenciar
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                              ),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Agenda Digital',
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors
                                          .black, // Color del texto según el tema
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1), // Color para diferenciar
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
                                    Icon(Icons.person,
                                        color: Theme.of(context)
                                                .iconTheme
                                                .color ??
                                            Colors
                                                .black), // Color del icono según el tema
                                    SizedBox(width: 8),
                                    Text(
                                      'Dr. ${data['lastName']}, ${data['name']}',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color ??
                                              Colors
                                                  .black, // Color del texto según el tema
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Theme.of(context)
                                                .iconTheme
                                                .color ??
                                            Colors
                                                .black), // Color del icono según el tema
                                    SizedBox(width: 8),
                                    Text(
                                      data['address'],
                                      style: TextStyle(
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color ??
                                              Colors
                                                  .black, // Color del texto según el tema
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.phone,
                                        color: Theme.of(context)
                                                .iconTheme
                                                .color ??
                                            Colors
                                                .black), // Color del icono según el tema
                                    SizedBox(width: 8),
                                    Text(
                                      data['phone'],
                                      style: TextStyle(
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color ??
                                              Colors
                                                  .black, // Color del texto según el tema
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                if (data.containsKey('specialty'))
                                  Row(
                                    children: [
                                      Icon(Icons.school,
                                          color: Theme.of(context)
                                                  .iconTheme
                                                  .color ??
                                              Colors
                                                  .black), // Color del icono según el tema
                                      SizedBox(width: 8),
                                      Text(
                                        data['specialty'],
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color ??
                                                Colors
                                                    .black, // Color del texto según el tema
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.1), // Color para diferenciar
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
                                    'lastName': data['lastName'],
                                    'name': data['name'],
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
                                      style: TextStyle(
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color ??
                                              Colors
                                                  .black), // Color del texto según el tema
                                    ),
                                    Icon(Icons.arrow_forward,
                                        color: Theme.of(context)
                                                .iconTheme
                                                .color ??
                                            Colors
                                                .black), // Color del icono según el tema
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
