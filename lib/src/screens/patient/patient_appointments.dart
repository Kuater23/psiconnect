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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person,
                                    color: Colors.blueAccent, size: 40),
                                SizedBox(width: 10),
                                Text(
                                  'Dr. ${data['lastName']}, ${data['name']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                                color:
                                    Colors.blueAccent), // Línea azul separadora
                            SizedBox(height: 10),
                            _buildInfoRow(Icons.location_on,
                                'Dirección: ${data['address']}'),
                            _buildInfoRow(
                                Icons.phone, 'Teléfono: ${data['phone']}'),
                            if (data.containsKey('specialty'))
                              _buildInfoRow(Icons.school,
                                  'Especialidad: ${data['specialty']}'),
                            SizedBox(height: 20),
                            Center(
                              child: OutlinedButton.icon(
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
                                icon: Icon(Icons.arrow_forward,
                                    color: Colors.blueAccent),
                                label: Text(
                                  'Ver agenda',
                                  style: TextStyle(color: Colors.blueAccent),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.blueAccent),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                  textStyle: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
