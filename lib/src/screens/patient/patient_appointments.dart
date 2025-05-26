import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';

class DoctorFields {
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String address = 'address';
  static const String phoneN = 'phoneN';
  static const String specialty = 'specialty';
}

class PatientAppointments extends StatefulWidget {
  final VoidCallback toggleTheme;

  const PatientAppointments({Key? key, required this.toggleTheme}) : super(key: key);

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
  ];

  @override
  Widget build(BuildContext context) {
    final String? patientId = FirebaseAuth.instance.currentUser?.uid;

    // Si no hay un paciente autenticado, se muestra un mensaje.
    if (patientId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Agenda Digital'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color.fromRGBO(2, 60, 67, 1),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: widget.toggleTheme,
            ),
          ],
        ),
        drawer: SharedDrawer(toggleTheme: widget.toggleTheme),
        body: Center(
          child: Text(
            'No se encontró el paciente autenticado',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Agenda Digital'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color.fromRGBO(2, 60, 67, 1),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
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
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
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
            child: ProfessionalList(selectedSpecialty: _selectedSpecialty),
          ),
        ],
      ),
    );
  }
}

class ProfessionalList extends StatelessWidget {
  final String? selectedSpecialty;

  const ProfessionalList({Key? key, this.selectedSpecialty}) : super(key: key);

  Stream<QuerySnapshot> _getFilteredStream() {
    if (selectedSpecialty != null && selectedSpecialty != 'Todas') {
      return FirebaseFirestore.instance
          .collection('doctors')
          .where('specialty', isEqualTo: selectedSpecialty)
          .snapshots();
    }
    return FirebaseFirestore.instance.collection('doctors').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final professionals = snapshot.data!.docs;
        
        return _buildProfessionalsList(context, professionals);
      },
    );
  }

  // Rest of the code remains the same...
}

  Widget _buildProfessionalsList(BuildContext context, List<QueryDocumentSnapshot> professionals) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultsCount(context, professionals.length),
            _buildProfessionalsGrid(context, professionals),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCount(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '$count resultados encontrados',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfessionalsGrid(BuildContext context, List<QueryDocumentSnapshot> professionals) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: professionals.map((professional) => 
        ProfessionalCard(professional: professional)).toList(),
    );
  }

class ProfessionalCard extends StatelessWidget {
  final QueryDocumentSnapshot professional;

  const ProfessionalCard({Key? key, required this.professional}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = professional.data() as Map<String, dynamic>;

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(data),
            const Divider(color: Colors.blueAccent),
            const SizedBox(height: 10),
            _buildInfoSection(data),
            const SizedBox(height: 20),
            _buildScheduleButton(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Row(
      children: [
        const Icon(Icons.person, color: Colors.blueAccent, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Dr. ${data[DoctorFields.lastName]}, ${data[DoctorFields.firstName]}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInfoRow(Icons.location_on, 'Dirección: ${data[DoctorFields.address]}'),
        _buildInfoRow(Icons.phone, 'Teléfono: ${data[DoctorFields.phoneN]}'),
        if (data.containsKey(DoctorFields.specialty))
          _buildInfoRow(Icons.school, 'Especialidad: ${data[DoctorFields.specialty]}'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleButton(BuildContext context, Map<String, dynamic> data) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _navigateToSchedule(context, data),
        icon: const Icon(Icons.arrow_forward, color: Colors.blueAccent),
        label: const Text('Ver agenda', style: TextStyle(color: Colors.blueAccent)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blueAccent),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _navigateToSchedule(BuildContext context, Map<String, dynamic> data) {
    Navigator.pushNamed(
      context,
      '/bookSchedule',
      arguments: {
        DoctorFields.lastName: data[DoctorFields.lastName],
        DoctorFields.firstName: data[DoctorFields.firstName],
      },
    );
  }
}
