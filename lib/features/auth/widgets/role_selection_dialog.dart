import 'package:Psiconnect/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RoleSelectionDialog extends StatelessWidget {
  const RoleSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona tu rol'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('Profesional'),
            onTap: () => Navigator.of(context).pop(UserRole.professional),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Paciente'),
            onTap: () => Navigator.of(context).pop(UserRole.patient),
          ),
        ],
      ),
    );
  }
}