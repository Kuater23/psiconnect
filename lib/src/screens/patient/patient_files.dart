import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Drawer compartido

class PatientFiles extends StatelessWidget {
  final String professionalId; // Profesional ID que se pasará desde la cita

  const PatientFiles({Key? key, required this.professionalId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(
          2, 60, 67, 1), // Color base de Psiconnect para el fondo
      appBar: AppBar(
        title: Text('Historial Clínico del Profesional $professionalId'),
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
      body: Center(
        child: Text(
          'Aquí se mostrarán los archivos médicos completos del profesional con ID $professionalId.',
          style: TextStyle(color: Colors.white), // Color del texto
        ),
      ),
    );
  }
}
