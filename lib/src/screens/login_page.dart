import 'package:Psiconnect/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';
import 'package:Psiconnect/src/screens/professional_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

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
            width: 300,
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextFields(),
                    SizedBox(height: 20),
                    _buildLoginButton(context, ref),
                    SizedBox(height: 10),
                    _buildGoogleLoginButton(context, ref),
                    SizedBox(height: 10),
                    _buildRegisterButton(context),
                    if (_isLoading) CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Función para construir los campos de texto
  Widget _buildTextFields() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
      ],
    );
  }

  // Función para construir el botón de inicio de sesión
  Widget _buildLoginButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        if (_validateInputs()) {
          _signInWithEmailAndPassword(context, ref);
        }
      },
      child: Text('Login'),
    );
  }

  // Función para construir el botón de inicio de sesión con Google
  Widget _buildGoogleLoginButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        _signInWithGoogle(context, ref);
      },
      child: Text('Login with Google'),
    );
  }

  // Función para construir el botón de registro
  Widget _buildRegisterButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterPage()),
        );
      },
      child: Text('¿Todavía no tienes una cuenta? Créala aquí mismo'),
    );
  }

  // Validar que los campos de entrada no estén vacíos
  bool _validateInputs() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter both email and password');
      return false;
    }
    return true;
  }

  // Función para manejar el inicio de sesión con email y contraseña
  Future<void> _signInWithEmailAndPassword(
      BuildContext context, WidgetRef ref) async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (user != null) {
        String role = await _authService.getUserRole(user.uid);
        ref.read(sessionProvider.notifier).logIn(user.email!, _passwordController.text);
        _navigateToRolePage(context, role);
      } else {
        _showErrorSnackBar('Login failed');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred during login');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para manejar el inicio de sesión con Google
  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        String role = await _authService.getUserRole(user.uid);
        ref.read(sessionProvider.notifier).logIn(user.email!, 'google_auth'); // Usar un marcador o token para Google
        _navigateToRolePage(context, role);
      } else {
        _showErrorSnackBar('Google login failed');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred during Google login');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para navegar a la página correspondiente según el rol del usuario
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
        page = HomePage();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // Función para mostrar un SnackBar con un mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
