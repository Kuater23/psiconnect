import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/professional_page.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: SizedBox(
          width: 300, // Ajusta el ancho según sea necesario
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Lógica para iniciar sesión con email y contraseña
                  User? user = await _authService.signInWithEmailAndPassword(
                    _emailController.text,
                    _passwordController.text,
                  );
                  if (user != null) {
                    // Obtener el rol del usuario desde Firestore
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    String role = userDoc['role'];

                    // Navegar a la pantalla correspondiente según el rol
                    if (role == 'patient') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => PatientPage()),
                      );
                    } else if (role == 'professional') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ProfessionalPage()),
                      );
                    } else if (role == 'admin') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AdminPage()),
                      );
                    }
                  } else {
                    // Manejo de error o cancelación del inicio de sesión
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al iniciar sesión')),
                    );
                  }
                },
                child: Text('Login'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  User? user = await _authService.signInWithGoogle();
                  if (user != null) {
                    // Obtener el rol del usuario desde Firestore
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    String role = userDoc['role'];

                    // Navegar a la pantalla correspondiente según el rol
                    if (role == 'patient') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => PatientPage()),
                      );
                    } else if (role == 'professional') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ProfessionalPage()),
                      );
                    } else if (role == 'admin') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AdminPage()),
                      );
                    }
                  } else {
                    // Manejo de error o cancelación del inicio de sesión
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al iniciar sesión')),
                    );
                  }
                },
                child: Text('Login with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}