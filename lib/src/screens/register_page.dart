import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/professional_page.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isProfessional = false; // Variable para controlar el switch

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 300, // Ajusta el ancho según sea necesario
                child: Column(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Paciente'),
                        Switch(
                          value: isProfessional,
                          onChanged: (value) {
                            setState(() {
                              isProfessional = value;
                            });
                          },
                        ),
                        Text('Profesional'),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        // Lógica para registrar con email y contraseña
                        String role = isProfessional ? 'professional' : 'patient';
                        User? user = await _authService.registerWithEmailAndPassword(
                          _emailController.text,
                          _passwordController.text,
                          role,
                        );
                        if (user != null) {
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
                          }
                        } else {
                          // Manejo de error o cancelación del registro
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al registrar')),
                          );
                        }
                      },
                      child: Text('Register'),
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
                      child: Text('Register with Google'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}