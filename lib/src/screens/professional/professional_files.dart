import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';

class ProfessionalFiles extends StatelessWidget {
  final String patientId; // Paciente ID que se pasará desde la cita

  const ProfessionalFiles({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial Clínico de $patientId'),
        automaticallyImplyLeading: true, // Permitir que aparezca el ícono del menú hamburguesa
      ),
      drawer: SharedDrawer(), 
      body: Center(
        child: Text('Aquí se mostrarán los archivos médicos completos del paciente con ID $patientId.'),
      ),
    );
  }
}
