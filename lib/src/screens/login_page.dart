import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
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
                        _buildTextFields(),
                        const SizedBox(height: 20),
                        _buildLoginButton(context, ref),
                        const SizedBox(height: 10),
                        _buildGoogleLoginButton(context, ref),
                        const SizedBox(height: 10),
                        _buildRegisterButton(context),
                        if (_isLoading) const CircularProgressIndicator(),
                      ],
                    ),
                  ),
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
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Ingrese su email',
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
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese su email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            hintText: 'Ingrese su contraseña',
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
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese su contraseña';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Función para construir el botón de inicio de sesión
  Widget _buildLoginButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          _signInWithEmailAndPassword(context, ref);
        }
      },
      child: const Text('Login'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }

  // Función para construir el botón de inicio de sesión con Google
  Widget _buildGoogleLoginButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        _signInWithGoogle(context, ref);
      },
      child: const Text('Login with Google'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
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
      child: const Text('¿Todavía no tienes una cuenta? Créala aquí mismo'),
    );
  }

  // Validar que los campos de entrada no estén vacíos
  bool _validateInputs() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar(
          'Por favor, ingresa tanto el correo como la contraseña.');
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
        ref
            .read(sessionProvider.notifier)
            .logIn(user.email!, _passwordController.text);
        _navigateToHomePage(context);
      } else {
        _showErrorSnackBar('Error en el inicio de sesión');
      }
    } catch (e) {
      _showErrorSnackBar('Ocurrió un error durante el inicio de sesión');
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
        ref.read(sessionProvider.notifier).logIn(user.email!, 'google_auth');
        _navigateToHomePage(context);
      } else {
        _showErrorSnackBar('Error en el inicio de sesión con Google');
      }
    } catch (e) {
      _showErrorSnackBar(
          'Ocurrió un error durante el inicio de sesión con Google');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para navegar a la HomePage tras un inicio de sesión exitoso
  void _navigateToHomePage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  // Función para mostrar un SnackBar con un mensaje de error
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
