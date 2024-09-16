import 'package:Psiconnect/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/professional/professional_home.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _identificationNumberController = TextEditingController(); // Número de Identificación Nacional
  final TextEditingController _nroMatriculaController = TextEditingController(); // Matrícula
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _identificationFocusNode = FocusNode();
  final FocusNode _nroMatriculaFocusNode = FocusNode();
  final ValueNotifier<String?> _emailErrorNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<String?> _passwordErrorNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<String?> _identificationErrorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _nroMatriculaErrorNotifier =
      ValueNotifier<String?>(null);

  bool isProfessional = false;
  bool _isLoading = false;

  // Agregamos un campo para el tipo de documento
  String? _selectedDocumentType; // Tipo de documento seleccionado

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
                    _buildLogo(),
                    SizedBox(height: 20),
                    _buildTextFields(),
                    SizedBox(height: 20),
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
                      child: Text('¿Ya tienes una cuenta? Inicia sesión aquí'),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 100,
        ),
        SizedBox(height: 10),
        Text(
          'Bienvenido a Psiconnect',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: _emailErrorNotifier,
          builder: (context, errorText, child) {
            return _buildTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Enter your email',
              errorText: errorText,
              focusNode: _emailFocusNode,
              icon: Icons.email,
            );
          },
        ),
        SizedBox(height: 16.0),
        ValueListenableBuilder<String?>(
          valueListenable: _passwordErrorNotifier,
          builder: (context, errorText, child) {
            return _buildTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              obscureText: true,
              errorText: errorText,
              focusNode: _passwordFocusNode,
              icon: Icons.lock,
            );
          },
        ),
        SizedBox(height: 16.0),
        if (isProfessional) ...[
          // Dropdown para el tipo de documento
          DropdownButtonFormField<String>(
            value: _selectedDocumentType,
            decoration: InputDecoration(labelText: 'Tipo de Documento'),
            items: ['DNI', 'Pasaporte', 'Otro'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedDocumentType = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor selecciona un tipo de documento';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          ValueListenableBuilder<String?>(
            valueListenable: _identificationErrorNotifier,
            builder: (context, errorText, child) {
              return _buildTextField(
                controller: _identificationNumberController,
                labelText: 'Número de Identificación Nacional',
                hintText: 'Enter your Identification Number',
                errorText: errorText,
                focusNode: _identificationFocusNode,
                icon: Icons.perm_identity,
              );
            },
          ),
          SizedBox(height: 16.0),
          ValueListenableBuilder<String?>(
            valueListenable: _nroMatriculaErrorNotifier,
            builder: (context, errorText, child) {
              return _buildTextField(
                controller: _nroMatriculaController,
                labelText: 'Matrícula Nacional',
                hintText: 'Enter your Matricula Nacional',
                errorText: errorText,
                focusNode: _nroMatriculaFocusNode,
                icon: Icons.badge,
              );
            },
          ),
          SizedBox(height: 16.0),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool obscureText = false,
    String? errorText,
    required FocusNode focusNode,
    required IconData icon,
  }) {
    return Container(
      width: 300,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          prefixIcon: Icon(icon),
        ),
        obscureText: obscureText,
      ),
    );
  }

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

  bool _validateInputs() {
    bool isValid = true;
    if (_emailController.text.isEmpty) {
      _emailErrorNotifier.value = 'Por favor, ingresa el correo.';
      _emailFocusNode.requestFocus();
      isValid = false;
    } else {
      _emailErrorNotifier.value = null;
    }

    if (_passwordController.text.isEmpty) {
      _passwordErrorNotifier.value = 'Por favor, ingresa la contraseña.';
      if (isValid) _passwordFocusNode.requestFocus();
      isValid = false;
    } else {
      _passwordErrorNotifier.value = null;
    }

    if (isProfessional) {
      if (_identificationNumberController.text.isEmpty) {
        _identificationErrorNotifier.value =
            'Por favor, ingresa el número de identificación.';
        if (isValid) _identificationFocusNode.requestFocus();
        isValid = false;
      } else {
        _identificationErrorNotifier.value = null;
      }

      if (_nroMatriculaController.text.isEmpty) {
        _nroMatriculaErrorNotifier.value =
            'Por favor, ingresa el número de matrícula.';
        if (isValid) _nroMatriculaFocusNode.requestFocus();
        isValid = false;
      } else {
        _nroMatriculaErrorNotifier.value = null;
      }

      if (_selectedDocumentType == null || _selectedDocumentType!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor selecciona un tipo de documento')),
        );
        isValid = false;
      }
    }

    return isValid;
  }

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
          if (isProfessional) 'idNumber': _identificationNumberController.text,
          if (isProfessional) 'documentType': _selectedDocumentType,
          if (isProfessional) 'matricula': _nroMatriculaController.text,
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
        page = ProfessionalHome();
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
