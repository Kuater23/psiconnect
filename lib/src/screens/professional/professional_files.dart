import 'package:flutter/material.dart';

class ProfessionalFiles extends StatelessWidget {
  final String patientId; // Paciente ID que se pasará desde la cita

  const ProfessionalFiles({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial Clínico de $patientId'),
      ),
      body: Center(
        child: Text('Aquí se mostrarán los archivos médicos completos del paciente con ID $patientId.'),
      ),
    );
  }
}
