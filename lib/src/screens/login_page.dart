import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        // Recuperar el rol desde Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc.get('role');
          ref.read(sessionProvider.notifier).logIn(user.email!, role);
          _navigateToHomePage(context);
        } else {
          _showErrorSnackBar('Error: No se pudo recuperar el rol del usuario.');
        }
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

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithGoogle();

      if (user != null) {
        // Verificar si el usuario ya existe en Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String role;
        if (userDoc.exists) {
          role = userDoc.get('role');
        } else {
          role = 'patient'; // Asignar un rol por defecto
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': user.email,
            'role': role,
          });
        }

        // Guardar el rol en el sessionProvider
        ref.read(sessionProvider.notifier).logIn(user.email!, role);
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

  void _navigateToHomePage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

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

  void _navigateToLoginPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
