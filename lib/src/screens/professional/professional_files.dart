import 'package:flutter/material.dart';

class ProfessionalFiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archivos por Paciente'),
      ),
      body: Center(
        child: Text(
          'Aquí se mostrarán los archivos relacionados con los pacientes',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
