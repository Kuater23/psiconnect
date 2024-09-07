import 'package:Psiconnect/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/professional_page.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';
import 'package:Psiconnect/src/screens/login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _nroMatriculaController = TextEditingController();
  bool isProfessional = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            child: Card(
              margin: EdgeInsets.all(16.0),
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email'),
                    SizedBox(height: 16.0),
                    _buildTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        obscureText: true),
                    SizedBox(height: 16.0),
                    if (isProfessional) ...[
                      _buildTextField(
                          controller: _dniController,
                          labelText: 'DNI',
                          hintText: 'Enter your DNI'),
                      SizedBox(height: 16.0),
                      _buildTextField(
                          controller: _nroMatriculaController,
                          labelText: 'Matricula Nacional',
                          hintText: 'Enter your Matricula Nacional'),
                      SizedBox(height: 16.0),
                    ],
                    _buildRoleSwitch(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Text('Register'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registerWithGoogle,
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Text('Register with Google'),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
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

  // Construir campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool obscureText = false,
  }) {
    return Container(
      width: 300,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 1.0),
          ),
          labelStyle: TextStyle(
            color: Colors.grey,
            fontSize: 16.0,
          ),
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: 14.0,
          ),
        ),
        obscureText: obscureText,
      ),
    );
  }

  // Construir interruptor de rol
  Widget _buildRoleSwitch() {
    return Row(
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
    );
  }

  // Validar los campos de entrada
  bool _validateInputs() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return false;
    }
    if (isProfessional &&
        (_dniController.text.isEmpty || _nroMatriculaController.text.isEmpty)) {
      _showErrorSnackBar(
          'Please fill in DNI and Matricula Nacional for professionals');
      return false;
    }
    return true;
  }

  // Registrar usuario con email y contraseña
  Future<void> _registerUser() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String role = isProfessional ? 'professional' : 'patient';
      User? user = await _authService.registerWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        role,
      );
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': _emailController.text,
          'role': role,
          if (isProfessional)
            'dni': _dniController.text,
          if (isProfessional)
            'matricula': _nroMatriculaController.text,
        });
        _navigateToRolePage(context, role);
      } else {
        _showErrorSnackBar('Error al registrar');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred during registration');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Registrar usuario con Google
  Future<void> _registerWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String role = userDoc.exists
            ? userDoc['role']
            : 'patient'; // Asignar rol por defecto si no existe
        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'role': role,
          });
        }
        _navigateToRolePage(context, role);
      } else {
        _showErrorSnackBar('Error al iniciar sesión con Google');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred during Google registration');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navegar a la página correspondiente según el rol
  void _navigateToRolePage(BuildContext context, String role) {
    Widget page;
    switch (role) {
      case 'admin':
        page = AdminPage();
        break;
      case 'patient':
        page = PatientPageWrapper();
        break;
      case 'professional':
        page = ProfessionalPage();
        break;
      default:
        page = LoginPage();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // Mostrar un SnackBar con un mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
