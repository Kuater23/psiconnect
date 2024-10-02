import 'package:flutter/material.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/login_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends ConsumerStatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final AuthService _authService = AuthService();

  // Controladores de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _identificationNumberController =
      TextEditingController();
  final TextEditingController _nroMatriculaController = TextEditingController();

  // Variables de estado para errores y carga
  bool _isLoading = false;
  bool _isProfessional = false;
  String? _emailError;
  String? _passwordError;
  String? _identificationError;
  String? _nroMatriculaError;
  String? _selectedDocumentType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(
          2, 60, 67, 1), // Color base de Psiconnect para el fondo
      appBar: AppBar(
        title: Text('Registro'),
        backgroundColor: Color.fromRGBO(
            2, 60, 67, 1), // Color base de Psiconnect para el fondo
        titleTextStyle: TextStyle(
          color: Colors.white, // Color de texto blanco
          fontSize: 24, // Tamaño del texto
          fontWeight: FontWeight.bold, // Negrita para el texto
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          _buildContent(context),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 350,
          child: Card(
            color: Color.fromRGBO(
                1, 40, 45, 1), // Color de fondo del contenedor del login
            margin: EdgeInsets.all(16.0),
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  SizedBox(height: 20),
                  _buildTextFields(),
                  SizedBox(height: 20),
                  _buildRoleSwitch(),
                  SizedBox(height: 20),
                  _buildRegisterButton(),
                  SizedBox(height: 10),
                  _buildGoogleRegisterButton(),
                  SizedBox(height: 20),
                  _buildLoginButton(),
                ],
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
            color: Colors.white, // Color del texto
          ),
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Ingresa tu email',
          errorText: _emailError,
          icon: Icons.email,
        ),
        SizedBox(height: 16.0),
        _buildTextField(
          controller: _passwordController,
          labelText: 'Contraseña',
          hintText: 'Ingresa tu contraseña',
          errorText: _passwordError,
          icon: Icons.lock,
          obscureText: true,
        ),
        if (_isProfessional) ...[
          SizedBox(height: 16.0),
          DropdownButtonFormField<String>(
            value: _selectedDocumentType,
            decoration: InputDecoration(
              labelText: 'Tipo de Documento',
              labelStyle: TextStyle(
                color: Color.fromRGBO(
                    11, 191, 205, 1), // Color del texto del label
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1), // Borde en el color especificado
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1), // Borde en el color especificado
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1), // Borde en el color especificado
                ),
              ),
            ),
            items: ['DNI', 'Pasaporte', 'Otro'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: Colors.black)),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedDocumentType = newValue;
              });
            },
            selectedItemBuilder: (BuildContext context) {
              return ['DNI', 'Pasaporte', 'Otro'].map((String value) {
                return Text(
                  value,
                  style: TextStyle(
                      color: Color.fromRGBO(
                          11, 191, 205, 1)), // Color del texto seleccionado
                );
              }).toList();
            },

            iconEnabledColor: Color.fromRGBO(
                11, 191, 205, 1), // Color del ícono del botón desplegable
          ),
          SizedBox(height: 16.0),
          _buildTextField(
            controller: _identificationNumberController,
            labelText: 'Número de Identificación',
            hintText: 'Ingresa tu número de identificación',
            errorText: _identificationError,
            icon: Icons.perm_identity,
          ),
          SizedBox(height: 16.0),
          _buildTextField(
            controller: _nroMatriculaController,
            labelText: 'Matrícula Nacional',
            hintText: 'Ingresa tu matrícula nacional',
            errorText: _nroMatriculaError,
            icon: Icons.badge,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    String? errorText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        labelStyle: TextStyle(
          color: Color.fromRGBO(11, 191, 205, 1), // Color del texto del label
        ),
        hintStyle: TextStyle(
          color: Color.fromRGBO(11, 191, 205, 1), // Color del texto del hint
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Color.fromRGBO(
                11, 191, 205, 1), // Borde en el color especificado
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Color.fromRGBO(
                11, 191, 205, 1), // Borde en el color especificado
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Color.fromRGBO(
                11, 191, 205, 1), // Borde en el color especificado
          ),
        ),
        prefixIcon: Icon(icon, color: Color.fromRGBO(11, 191, 205, 1)),
      ),
      style: TextStyle(
        color: Color.fromRGBO(11, 191, 205, 1), // Color del texto del campo
      ),
      obscureText: obscureText,
    );
  }

  Widget _buildRoleSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Paciente'),
        Switch(
          value: _isProfessional,
          onChanged: (value) {
            setState(() {
              _isProfessional = value;
            });
          },
        ),
        Text('Profesional'),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {
              await _registerUser();
            },
      child: Text('Registrarse'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildGoogleRegisterButton() {
    return SignInButton(
      Buttons.Google,
      text: 'Registrarse con Google',
      onPressed: () {
        _registerWithGoogle(); // Function is called only when the button is pressed
      },
    );
  }

  Widget _buildLoginButton() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
      child: Text('¿Ya tienes una cuenta? Inicia sesión aquí'),
    );
  }

  bool _validateInputs() {
    bool isValid = true;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _identificationError = null;
      _nroMatriculaError = null;
    });

    if (_emailController.text.isEmpty) {
      _emailError = 'Por favor, ingresa el correo.';
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      _emailError = 'Correo inválido.';
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      _passwordError = 'Por favor, ingresa la contraseña.';
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      _passwordError = 'La contraseña debe tener al menos 6 caracteres.';
      isValid = false;
    }

    if (_isProfessional) {
      if (_selectedDocumentType == null || _selectedDocumentType!.isEmpty) {
        _showErrorSnackBar('Por favor, selecciona un tipo de documento.');
        isValid = false;
      }

      if (_identificationNumberController.text.isEmpty) {
        _identificationError =
            'Por favor, ingresa el número de identificación.';
        isValid = false;
      }

      if (_nroMatriculaController.text.isEmpty) {
        _nroMatriculaError = 'Por favor, ingresa el número de matrícula.';
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
      String role = _isProfessional ? 'professional' : 'patient';
      User? user = await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        role,
      );

      if (user != null) {
        if (_isProfessional) {
          await _authService.updateProfessionalInfo(
            uid: user.uid,
            documentType: _selectedDocumentType!,
            idNumber: _identificationNumberController.text.trim(),
            matricula: _nroMatriculaController.text.trim(),
          );
        }

        // Navegar a la ruta '/home' para que AuthWrapper maneje la redirección
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
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
      // Sign in with Google
      User? user = await _authService.signInWithGoogle();

      if (user != null) {
        // Show role selection dialog and wait for the user's choice
        await _showRoleSelectionDialog();

        // Determine the user's role based on the selection
        String role = _isProfessional ? 'professional' : 'patient';

        // Update the user's role in Firestore
        await _authService.updateUserRole(user.uid, role);

        // If the user is a professional, update additional professional information
        if (_isProfessional) {
          // Ensure that document type and identification number are valid
          if (_selectedDocumentType == null ||
              _identificationNumberController.text.trim().isEmpty) {
            _showErrorSnackBar(
                'Please provide all required professional information.');
            return;
          }

          await _authService.updateProfessionalInfo(
            uid: user.uid,
            documentType: _selectedDocumentType!,
            idNumber: _identificationNumberController.text.trim(),
            matricula: _nroMatriculaController.text.trim(),
          );
        }

        // Navigate to the home route after registration and role selection
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      // Show an error message in a snackbar if something goes wrong
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      // Ensure the loading state is reset
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showRoleSelectionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isProfessionalTemp = false;
        return AlertDialog(
          title: Text('Selecciona tu rol'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    title: Text('Paciente'),
                    value: false,
                    groupValue: isProfessionalTemp,
                    onChanged: (bool? value) {
                      setStateDialog(() {
                        isProfessionalTemp = value!;
                      });
                    },
                  ),
                  RadioListTile<bool>(
                    title: Text('Profesional'),
                    value: true,
                    groupValue: isProfessionalTemp,
                    onChanged: (bool? value) {
                      setStateDialog(() {
                        isProfessionalTemp = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                setState(() {
                  _isProfessional = isProfessionalTemp;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
