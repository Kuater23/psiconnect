import 'package:Psiconnect/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/professional_page.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/login_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _nroMatriculaController = TextEditingController();
  bool isProfessional = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nroMatriculaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Image.asset(
                          'assets/images/logo.png', // Asegúrate de tener el logo en esta ruta
                          height: 100,
                        ),
                      ),
                      _buildTextField(
                        controller: _dniController,
                        labelText: 'DNI',
                        hintText: 'Ingrese su DNI',
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextField(
                        controller: _firstNameController,
                        labelText: 'Nombre',
                        hintText: 'Ingrese su nombre',
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextField(
                        controller: _lastNameController,
                        labelText: 'Apellido',
                        hintText: 'Ingrese su apellido',
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Ingrese su email',
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextField(
                        controller: _passwordController,
                        labelText: 'Contraseña',
                        hintText: 'Ingrese su contraseña',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Re-Contraseña',
                        hintText: 'Confirme su contraseña',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16.0),
                      if (isProfessional) ...[
                        _buildTextField(
                          controller: _nroMatriculaController,
                          labelText: 'Matrícula Nacional',
                          hintText: 'Ingrese su Matrícula Nacional',
                        ),
                        const SizedBox(height: 16.0),
                      ],
                      _buildRoleSwitch(),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Registrar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 30.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _registerWithGoogle,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Registrar con Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors
                              .blueAccent, // Color similar al botón de registro
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 30.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        child: const Text(
                            '¿Todavía no tienes una cuenta? Créala aquí mismo'),
                      ),
                    ],
                  ),
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 16.0,
          ),
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14.0,
          ),
        ),
        obscureText: obscureText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese $labelText';
          }
          return null;
        },
      ),
    );
  }

  // Construir interruptor de rol
  Widget _buildRoleSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Paciente'),
        Switch(
          value: isProfessional,
          onChanged: (value) {
            setState(() {
              isProfessional = value;
            });
          },
        ),
        const Text('Profesional'),
      ],
    );
  }

  // Validar los campos de entrada
  bool _validateInputs() {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Por favor complete todos los campos');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Las contraseñas no coinciden');
      return false;
    }
    if (isProfessional &&
        (_dniController.text.isEmpty || _nroMatriculaController.text.isEmpty)) {
      _showErrorSnackBar(
          'Por favor complete DNI y Matrícula Nacional para profesionales');
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
          'dni': _dniController.text,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'role': role,
          if (isProfessional) 'matricula': _nroMatriculaController.text,
        });
        _navigateToRolePage(context, role);
      } else {
        _showErrorSnackBar('Error al registrar');
      }
    } catch (e) {
      _showErrorSnackBar('Ocurrió un error durante el registro');
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
      _showErrorSnackBar('Ocurrió un error durante el registro con Google');
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
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }
}
