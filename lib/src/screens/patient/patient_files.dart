import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Drawer compartido

class PatientFiles extends StatelessWidget {
  final String professionalId; // Profesional ID que se pasará desde la cita
  final VoidCallback toggleTheme;

  const PatientFiles(
      {Key? key,
      required this.professionalId,
      required String patientId,
      required this.toggleTheme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Fondo según el tema
      appBar: AppBar(
        title: Text('Historial Clínico del Profesional $professionalId'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Color.fromRGBO(
                2, 60, 67, 1), // Color base de Psiconnect para el fondo
        titleTextStyle: TextStyle(
          color: Colors.white, // Color de texto blanco
          fontSize: 24, // Tamaño del texto
          fontWeight: FontWeight.bold, // Negrita para el texto
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(
          toggleTheme: toggleTheme), // Utilizar el Drawer compartido
      body: Center(
        child: Text(
          'Aquí se mostrarán los archivos médicos completos del profesional con ID $professionalId.',
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.black), // Color del texto según el tema
        ),
      ),
    );
  }
}
