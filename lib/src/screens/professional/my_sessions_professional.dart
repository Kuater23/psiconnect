import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';

class MySessionsProfessionalPage extends StatelessWidget {
  final VoidCallback toggleTheme;

  const MySessionsProfessionalPage({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Sesiones'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? 
            const Color.fromRGBO(2, 60, 67, 1),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(toggleTheme: toggleTheme),
      body: _buildBody(user, context),
    );
  }

  Widget _buildBody(User? user, BuildContext context) {
    if (user == null) {
      return const Center(child: Text('No estás autenticado'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('professionalId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar las sesiones'));
        }

        final sessions = snapshot.data?.docs ?? [];

        if (sessions.isEmpty) {
          return const Center(child: Text('No tienes sesiones reservadas'));
        }

        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) => _buildSessionCard(sessions[index], context),
        );
      },
    );
  }

  Widget _buildSessionCard(DocumentSnapshot session, BuildContext context) {
    final sessionData = session.data() as Map<String, dynamic>;
    final appointmentDate = DateTime.parse(sessionData['date']);
    final isUpcoming = appointmentDate.isAfter(DateTime.now());

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('patients')
          .doc(sessionData['patientId'])
          .get(),
      builder: (context, patientSnapshot) {
        if (patientSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (patientSnapshot.hasError || !patientSnapshot.hasData) {
          return const Center(child: Text('Error al cargar los datos del paciente'));
        }

        final patientData = patientSnapshot.data!.data() as Map<String, dynamic>;

        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.all(10),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientHeader(patientData, context),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                _buildAppointmentInfo(sessionData, patientData, context, isUpcoming),
                const SizedBox(height: 16),
                if (isUpcoming) _buildCancelButton(context, session.id),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientHeader(Map<String, dynamic> patientData, BuildContext context) {
    return Text(
      'Paciente: ${patientData['firstName']} ${patientData['lastName']}',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
    );
  }

  Widget _buildAppointmentInfo(
    Map<String, dynamic> sessionData,
    Map<String, dynamic> patientData,
    BuildContext context,
    bool isUpcoming,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUpcoming ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isUpcoming ? 'Próxima' : 'Pasada',
                style: TextStyle(
                  color: isUpcoming ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildInfoRow(
          icon: Icons.calendar_today,
          text: 'Día y hora reservado: ${sessionData['appointmentDay']}',
          context: context,
        ),
        const SizedBox(height: 10),
        _buildInfoRow(
          icon: Icons.email,
          text: 'Email: ${patientData['email']}',
          context: context,
        ),
        const SizedBox(height: 10),
        _buildInfoRow(
          icon: Icons.phone,
          text: 'Teléfono: ${patientData['phoneN']}',
          context: context,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).iconTheme.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context, String appointmentId) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _cancelAppointment(context, appointmentId),
        icon: const Icon(Icons.cancel, color: Colors.red),
        label: const Text(
          'Cancelar Cita',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(BuildContext context, String appointmentId) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Cancelar Cita'),
            content: const Text('¿Está seguro que desea cancelar esta cita?'),
            actions: <Widget>[
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Sí'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita cancelada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar la cita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}