import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';

class ProfessionalFiles extends StatelessWidget {
  final String patientId; // Paciente ID que se pasará desde la cita
  final VoidCallback toggleTheme;

  const ProfessionalFiles(
      {Key? key, required this.patientId, required this.toggleTheme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Fondo según el tema
      appBar: AppBar(
        title: Text('Historial Clínico de $patientId'),
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
        automaticallyImplyLeading:
            true, // Permitir que aparezca el ícono del menú hamburguesa
      ),
      drawer: SharedDrawer(toggleTheme: toggleTheme),
      body: Center(
        child: Text(
          'Aquí se mostrarán los archivos médicos completos del paciente con ID $patientId.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color ??
                Colors.black, // Color del texto según el tema
          ),
        ),
      ),
    );
  }
}
