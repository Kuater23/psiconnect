import 'package:flutter/material.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedDrawer extends ConsumerStatefulWidget {
  @override
  _SharedDrawerState createState() => _SharedDrawerState();
}

class _SharedDrawerState extends ConsumerState<SharedDrawer> {
  final AuthService _authService = AuthService(); // Servicio de autenticación
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userRole = userDoc['role'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

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
              'Menú ${_userRole == 'professional' ? 'Profesional' : 'Paciente'}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Inicio'),
            onTap: () {
              Navigator.pushReplacementNamed(
                  context, '/home'); // Redirige a HomePage
            },
          ),
          if (_userRole == 'professional') ...[
            ListTile(
              title: Text('Home Profesional'),
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, '/professional'); // Redirige a ProfessionalHome
              },
            ),
            ListTile(
              title: Text('Citas'),
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, '/professional_appointments');
              },
            ),
            ListTile(
              title: Text('Archivos por Paciente'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/professional_files');
              },
            ),
          ] else if (_userRole == 'patient') ...[
            ListTile(
              title: Text('Información del Paciente'),
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, '/patient'); // Redirige a PatientPage
              },
            ),
            ListTile(
              title: Text('Citas'),
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, '/patient_appointments');
              },
            ),
            ListTile(
              title: Text('Archivos'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/patient_files');
              },
            ),
          ],
          SizedBox(height: 20),
          ListTile(
            title: Text('Cerrar Sesión'),
            leading: Icon(Icons.logout),
            onTap: () async {
              await _signOut(
                  context, ref); // Cerrar sesión y redirigir al login
            },
          ),
        ],
      ),
    );
  }

  // Método para cerrar sesión y redirigir a la HomePage
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await _authService
          .signOut(); // Llamamos al servicio de autenticación para cerrar sesión
      ref
          .read(sessionProvider.notifier)
          .logOut(); // Limpiamos la sesión del provider
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
