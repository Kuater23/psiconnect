import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/service/auth_service.dart';
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart'; // Para botones de inicio de sesión estilizados

class LoginPage extends ConsumerStatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estados para controlar errores y carga
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  bool _obscurePassword =
      true; // Para controlar si la contraseña se muestra o no

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(
          2, 60, 67, 1), // Color base de Psiconnect para el fondo
      appBar: AppBar(
        title: Text('Iniciar Sesión'),
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
      body: SingleChildScrollView(
        child: Stack(
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
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(11, 191, 205, 1), // Color del texto
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Inicie Sesión para continuar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white, // Color del texto
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: 300,
                child: Card(
                  color: Color.fromRGBO(
                      1, 40, 45, 1), // Color de fondo del contenedor del login
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
                        _buildLoginButton(context),
                        SizedBox(height: 10),
                        _buildGoogleLoginButton(context),
                        SizedBox(height: 10),
                        _buildRegisterButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(20.0), // Radio de los ángulos redondeados
          child: Image.asset(
            'assets/images/logo.png',
            height: 100,
            fit: BoxFit
                .contain, // Asegurar que la imagen se ajuste dentro del contenedor
          ),
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
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
                color: Color.fromRGBO(
                    11, 191, 205, 1)), // Color del texto del label
            errorText: _emailError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1)), // Borde en el color especificado
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1)), // Borde en el color especificado
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1)), // Borde en el color especificado
            ),
            prefixIcon: Icon(Icons.email,
                color: Color.fromRGBO(
                    11, 191, 205, 1)), // Icono en el color especificado
          ),
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
              color: Color.fromRGBO(
                  11, 191, 205, 1)), // Color del texto en el color especificado
        ),
        SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            labelStyle: TextStyle(
                color: Color.fromRGBO(
                    11, 191, 205, 1)), // Color del texto del label
            errorText: _passwordError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1)), // Borde en el color especificado
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1)), // Borde en el color especificado
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1)), // Borde en el color especificado
            ),
            prefixIcon: Icon(Icons.lock,
                color: Color.fromRGBO(
                    11, 191, 205, 1)), // Icono en el color especificado
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Color.fromRGBO(
                    11, 191, 205, 1), // Icono en el color especificado
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          style: TextStyle(
              color: Color.fromRGBO(
                  11, 191, 205, 1)), // Color del texto en el color especificado
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (_validateInputs()) {
          await _signInWithEmailAndPassword(context);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Color de fondo del botón
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 10, // Aumentar la sombra para el botón
      ),
      child: Text(
        'Iniciar Sesión',
        style: TextStyle(
          color: Color.fromRGBO(154, 141, 140, 1), // Color del texto en RGBO
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4), // Hacer la sombra más oscura
            spreadRadius: 4, // Aumentar el spreadRadius
            blurRadius: 10, // Aumentar el blurRadius
            offset: Offset(0, 3), // Sombra para el botón
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: SignInButton(
          Buttons.Google,
          text: 'Iniciar Sesión con Google',
          onPressed: () async {
            await _signInWithGoogle(context);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
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
      child: Text(
        '¿Todavía no tienes una cuenta? Regístrate aquí',
        style: TextStyle(
            color: Color.fromRGBO(11, 191, 205, 1)), // Color del texto
      ),
    );
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Por favor, ingresa el correo.';
      });
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() {
        _emailError = 'Correo inválido.';
      });
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Por favor, ingresa la contraseña.';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _signInWithEmailAndPassword(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Error al iniciar sesión.');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithGoogle();

      if (user != null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Error al iniciar sesión con Google.');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
