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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final ValueNotifier<String?> _emailErrorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _passwordErrorNotifier = ValueNotifier<String?>(null);
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
          child: SingleChildScrollView(
            child: Container(
              width: 300,
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(),
                      SizedBox(height: 20),
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
      ),
    );
  }

  // Función para construir el logo
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

  // Función para construir los campos de texto
  Widget _buildTextFields() {
    return Column(
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: _emailErrorNotifier,
          builder: (context, errorText, child) {
            return TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            );
          },
        ),
        SizedBox(height: 10),
        ValueListenableBuilder<String?>(
          valueListenable: _passwordErrorNotifier,
          builder: (context, errorText, child) {
            return TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            );
          },
        ),
      ],
    );
  }

  // Función para construir el botón de inicio de sesión
  Widget _buildLoginButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        if (_validateInputs()) {
          await _signInWithEmailAndPassword(context, ref);
        }
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text('Login'),
    );
  }

  // Función para construir el botón de inicio de sesión con Google
  Widget _buildGoogleLoginButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        await _signInWithGoogle(context, ref);
      },
      icon: Icon(Icons.login),
      label: Text('Login with Google'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
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
      child: Text('¿Todavía no tienes una cuenta? Créala aquí mismo'),
    );
  }

  // Validar que los campos de entrada no estén vacíos
  bool _validateInputs() {
    bool isValid = true;

    if (_emailController.text.isEmpty) {
      _emailErrorNotifier.value = 'Por favor, ingresa el correo.';
      _emailFocusNode.requestFocus();
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      _emailErrorNotifier.value = 'Correo inválido.';
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

    return isValid;
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
      _showErrorSnackBar('Error: ${e.toString()}');
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
      _showErrorSnackBar('Error: ${e.toString()}');
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

  // Función para manejar el cierre de sesión
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signOut();
      ref.read(sessionProvider.notifier).logOut();
      _navigateToLoginPage(context);
    } catch (e) {
      _showErrorSnackBar('Error al cerrar sesión: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para navegar de regreso a la página de login tras el cierre de sesión
  void _navigateToLoginPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Función para mostrar un SnackBar con un mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
