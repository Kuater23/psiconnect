import 'package:flutter/material.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userRoleProvider = StateProvider<String?>((ref) => null);

class SharedDrawer extends ConsumerStatefulWidget {
  @override
  _SharedDrawerState createState() => _SharedDrawerState();
}

class _SharedDrawerState extends ConsumerState<SharedDrawer> {
  final AuthService _authService = AuthService();
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
      final role = userDoc['role'] as String?;
      ref.read(userRoleProvider.notifier).state = role;
      setState(() {
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
    final userRole = ref.watch(userRoleProvider); // Acceso directo al rol

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Contenedor en lugar de DrawerHeader para controlar mejor la altura
          Container(
            height: 90, // Ajusta la altura
            decoration: BoxDecoration(
              color: const Color.fromRGBO(1, 40, 45, 1), // Fondo verde
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el drawer
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/logoCompleto_psiconnect.png', // Ruta del logo
                    width: MediaQuery.of(context).size.width *
                        0.4, // Ajusta el tamaño
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Inicio'),
            onTap: () {
              Navigator.pushReplacementNamed(
                  context, '/home'); // Redirige a HomePage
            },
          ),
          if (userRole == 'professional') ...[
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Perfil'),
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, '/professional'); // Redirige a ProfessionalHome
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Agenda'),
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, '/professional_appointments');
              },
            ),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text('Archivos por Paciente'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/professional_files');
              },
            ),
          ] else if (userRole == 'patient') ...[
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Perfil del Paciente'),
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, '/patient'); // Redirige a PatientPage
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Agenda'),
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, '/patient_appointments');
              },
            ),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text('Archivos'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/patient_files');
              },
            ),
          ],
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar Sesión'),
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
