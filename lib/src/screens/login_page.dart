import 'package:Psiconnect/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/register_page.dart'; // Asegúrate de importar la página de registro
import 'package:Psiconnect/src/screens/home_page.dart'; // Asegúrate de importar la página principal
import 'package:Psiconnect/src/screens/admin_page.dart'; // Asegúrate de importar la página de Admin
import 'package:Psiconnect/src/screens/patient_page.dart'; // Asegúrate de importar la página de Paciente
import 'package:Psiconnect/src/screens/professional_page.dart'; // Asegúrate de importar la página de Profesional
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Importa hooks_riverpod
import 'package:Psiconnect/src/navigation_bar/session_provider.dart'; // Importa el sessionProvider

class LoginPage extends ConsumerStatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: 300, // Ajusta el ancho de la Card aquí
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
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
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        User? user =
                            await _authService.signInWithEmailAndPassword(
                          _emailController.text,
                          _passwordController.text,
                        );
                        if (user != null) {
                          String role =
                              await _authService.getUserRole(user.uid);
                          ref
                              .read(sessionProvider.notifier)
                              .logIn(user); // Actualiza el estado de la sesión
                          if (role == 'admin') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdminPage()),
                            );
                          } else if (role == 'patient') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PatientPageWrapper()),
                            );
                          } else if (role == 'professional') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfessionalPage()),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()),
                            );
                          }
                        } else {
                          // Mostrar un mensaje de error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Login failed')),
                          );
                        }
                      },
                      child: Text('Login'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        User? user = await _authService.signInWithGoogle();
                        if (user != null) {
                          String role =
                              await _authService.getUserRole(user.uid);
                          ref
                              .read(sessionProvider.notifier)
                              .logIn(user); // Actualiza el estado de la sesión
                          if (role == 'admin') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdminPage()),
                            );
                          } else if (role == 'patient') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PatientPageWrapper()),
                            );
                          } else if (role == 'professional') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfessionalPage()),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()),
                            );
                          }
                        } else {
                          // Mostrar un mensaje de error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Google login failed')),
                          );
                        }
                      },
                      child: Text('Login with Google'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterPage()),
                        );
                      },
                      child: Text(
                          '¿Todavía no tienes una cuenta? Créala aquí mismo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
