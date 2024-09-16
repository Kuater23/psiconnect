import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Importa el Drawer compartido

class ProfessionalAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Citas Profesionales'),
      ),
      drawer: SharedDrawer(), // Añade el menú hamburguesa compartido
      body: Center(
        child: Text('Aquí se mostrarán las citas del profesional.'),
      ),
    );
  }
}
