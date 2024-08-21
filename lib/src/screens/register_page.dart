import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'login_page.dart'; // Asegúrate de importar la página de login
import 'admin_page.dart';
import 'patient_page.dart';
import 'professional_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController dniController = TextEditingController();
  final TextEditingController matriculaController = TextEditingController();
  final TextEditingController generoController = TextEditingController();

  bool isProfessional = false;

  Future<void> _handleRegisterWithGoogle() async {
    User? user = await _authService.signInWithGoogle();
    if (user != null) {
      // Verificar si el usuario ya existe en Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Si el usuario no existe, registrarlo con el rol seleccionado
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': isProfessional ? 'professional' : 'patient',
          if (isProfessional) 'dni': dniController.text,
          if (isProfessional) 'matricula': matriculaController.text,
          if (isProfessional) 'genero': generoController.text,
        });
      }

      // Obtener el rol del usuario desde Firestore
      userDoc = await FirebaseFirestore.instance
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
      // Manejo de error o cancelación del registro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrarse')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      backgroundColor: Color.fromARGB(255, 0, 153, 255), // Establece el color de fondo aquí
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: 400.0, // Establece el ancho deseado aquí
            height: 600.0, // Establece el largo deseado aquí
            child: Card(
              color: Color.fromARGB(255, 158, 216, 255), // Establece el color de la Card aquí
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos verticalmente
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(labelText: 'Confirmar Contraseña'),
                      obscureText: true,
                    ),
                    if (isProfessional) ...[
                      SizedBox(height: 16.0),
                      TextField(
                        controller: dniController,
                        decoration: InputDecoration(labelText: 'DNI'),
                      ),
                      SizedBox(height: 16.0),
                      TextField(
                        controller: matriculaController,
                        decoration: InputDecoration(labelText: 'Número de Matrícula'),
                      ),
                      SizedBox(height: 16.0),
                      TextField(
                        controller: generoController,
                        decoration: InputDecoration(labelText: 'Género'),
                      ),
                    ],
                    SizedBox(height: 16.0),
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
                    SizedBox(height: 8.0), // Reducimos el tamaño del SizedBox
                    ElevatedButton(
                      onPressed: () {
                        // Implement register logic here
                      },
                      child: Text('Registrarse'),
                    ),
                    SizedBox(height: 8.0), // Reducimos el tamaño del SizedBox
                    ElevatedButton(
                      onPressed: _handleRegisterWithGoogle,
                      child: Text('Registrarse con Google'),
                      style: ElevatedButton.styleFrom(
                        //primary: Colors.red, // Color del botón de Google
                      ),
                    ),
                    SizedBox(height: 8.0), // Reducimos el tamaño del SizedBox
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text('¿Ya tienes cuenta? Inicia sesión aquí'),
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