import 'package:flutter/material.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';
import 'package:Psiconnect/src/screens/home_page.dart';

class SharedDrawer extends ConsumerWidget {
  final AuthService _authService = AuthService(); // Servicio de autenticación

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Botón para cerrar el drawer
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el drawer
              },
            ),
          ),
          DrawerHeader(
            decoration: BoxDecoration(
                  color: const Color.fromRGBO(1, 40, 45, 1), // Fondo de Psiconnect
            ),
            child: Text(
              'Menú Profesional',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Inicio'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home'); // Redirige a HomePage
            },
          ),
          ListTile(
            title: Text('Home Profesional'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/professional'); // Redirige a ProfessionalHome
            },
          ),
          ListTile(
            title: Text('Citas'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/professional_appointments');
            },
          ),
          ListTile(
            title: Text('Archivos por Paciente'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/professional_files');
            },
          ),
          SizedBox(height: 20),
          ListTile(
            title: Text('Cerrar Sesión'),
            leading: Icon(Icons.logout),
            onTap: () async {
              await _signOut(context, ref); // Cerrar sesión y redirigir al login
            },
          ),
        ],
      ),
    );
  }

  // Método para cerrar sesión y redirigir a la HomePage
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await _authService.signOut(); // Llamamos al servicio de autenticación para cerrar sesión
      ref.read(sessionProvider.notifier).logOut(); // Limpiamos la sesión del provider
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false, // Eliminar todas las rutas previas
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión')),
      );
    }
  }
}
