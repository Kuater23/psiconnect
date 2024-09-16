import 'package:flutter/material.dart';

class ProfessionalAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Citas Profesionales'),
      ),
      body: Center(
        child: Text(
          'Aquí se mostrarán las citas del profesional',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
