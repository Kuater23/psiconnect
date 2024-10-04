import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Drawer compartido

class PatientFiles extends StatelessWidget {
  final String professionalId; // Profesional ID que se pasará desde la cita

  const PatientFiles(
      {Key? key, required this.professionalId, required String patientId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial Clínico del Profesional $professionalId'),
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
            'Aquí se mostrarán los archivos médicos completos del profesional con ID $professionalId.'),
      ),
    );
  }
}
