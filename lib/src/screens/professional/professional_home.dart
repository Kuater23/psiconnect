import 'package:flutter/material.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';

class ProfessionalHome extends ConsumerWidget {
  final AuthService _authService = AuthService(); // Servicio de autenticación

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Información del Profesional'),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home'); // Redirige a la HomePage
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref), // Menú lateral con opciones
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfessionalInfo(),
            SizedBox(height: 20),
            Text(
              'Próximos Pacientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(child: _buildUpcomingPatients()), // Resumen de los próximos pacientes
          ],
        ),
      ),
    );
  }

  // Información básica del profesional
  Widget _buildProfessionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dr. John Doe', // Reemplazar con datos dinámicos
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Especialista en Psicología Clínica',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 10),
        Text(
          'Consultorio: Av. Siempreviva 123',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Teléfono: +54 9 1234-5678',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Email: dr.johndoe@example.com',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // Resumen de los próximos pacientes
  Widget _buildUpcomingPatients() {
    // Datos de ejemplo, estos deberían cargarse dinámicamente
    final List<Map<String, String>> patients = [
      {'name': 'Paciente 1', 'date': '2024-09-15', 'time': '10:00 AM'},
      {'name': 'Paciente 2', 'date': '2024-09-15', 'time': '11:30 AM'},
      {'name': 'Paciente 3', 'date': '2024-09-16', 'time': '9:00 AM'},
    ];

    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          child: ListTile(
            title: Text(patient['name']!),
            subtitle: Text('Fecha: ${patient['date']} - Hora: ${patient['time']}'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Lógica para ver detalles del paciente
            },
          ),
        );
      },
    );
  }

  // Menú lateral con las opciones de la página y cerrar sesión
  Drawer _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menú Profesional',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Inicio'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home'); // Redirige a la HomePage sin cerrar sesión
            },
          ),
          ListTile(
            title: Text('Home Profesional'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/professional_home');
            },
          ),
          ListTile(
            title: Text('Citas'),
            onTap: () {
              Navigator.pushNamed(context, '/professional_appointments');
            },
          ),
          ListTile(
            title: Text('Archivos por Paciente'),
            onTap: () {
              Navigator.pushNamed(context, '/professional_files');
            },
          ),
          SizedBox(height: 20),
          ListTile(
            title: Text('Cerrar Sesión'),
            leading: Icon(Icons.logout),
            onTap: () async {
              await _signOut(context, ref); // Cerrar sesión y redirigir al login
            },
          ),
        ],
      ),
    );
  }

  // Cerrar sesión y redirigir a la HomePage
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      // Llamamos al servicio de autenticación para cerrar sesión
      await _authService.signOut();
      
      // Limpiamos la sesión del provider
      ref.read(sessionProvider.notifier).logOut();

      // Redirigimos a la página de inicio (HomePage)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false, // Eliminar todas las rutas previas
      );
    } catch (e) {
      // Mostrar un mensaje de error si ocurre un problema
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión')),
      );
    }
  }
}
