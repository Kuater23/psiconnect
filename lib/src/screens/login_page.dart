import 'package:flutter/material.dart';
import 'package:Psiconnect/src/providers/auth_providers.dart'; // Proveedor de estado de autenticación.
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword =
      true; // Para controlar si la contraseña se muestra o no

  @override
  Widget build(BuildContext context) {
    final authState =
        ref.watch(authNotifierProvider); // Escucha el estado de autenticación.

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
      body: Stack(
        children: [
          _buildContent(context, ref),
          if (authState ==
              AuthStatus
                  .loading) // Muestra loader cuando el estado es 'loading'.
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

  Widget _buildContent(BuildContext context, WidgetRef ref) {
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
                  fontSize: 40, // Tamaño grande del título
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
                width: 300, // Controlar el ancho de los campos
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
                        _buildLoginButton(context, ref),
                        SizedBox(height: 10),
                        _buildGoogleLoginButton(context, ref),
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
          borderRadius: BorderRadius.circular(20.0), // Ángulos redondeados
          child: Image.asset(
            'assets/images/logo.png',
            height: 100,
            fit: BoxFit.contain, // Mantener el tamaño adecuado de la imagen
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
        // Campo de Email
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
                color: Color.fromRGBO(11, 191, 205, 1)), // Color del label
            border: OutlineInputBorder(
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
              color: Color.fromRGBO(11, 191, 205, 1)), // Color del texto
        ),
        SizedBox(height: 10),
        // Campo de Contraseña
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword, // Contraseña oculta
          decoration: InputDecoration(
            labelText: 'Contraseña',
            labelStyle: TextStyle(
                color: Color.fromRGBO(11, 191, 205, 1)), // Color del label
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                  color: Color.fromRGBO(
                      11, 191, 205, 1)), // Borde en el color especificado
            ),
            prefixIcon: Icon(Icons.lock,
                color: Color.fromRGBO(11, 191, 205, 1)), // Icono
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Color.fromRGBO(11, 191, 205, 1), // Color del icono
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword =
                      !_obscurePassword; // Alternar visibilidad de la contraseña
                });
              },
            ),
          ),
          style: TextStyle(
              color: Color.fromRGBO(11, 191, 205, 1)), // Color del texto
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        if (_validateInputs(context)) {
          await ref.read(authNotifierProvider.notifier).signInWithEmail(
                _emailController.text.trim(),
                _passwordController.text,
              );
          if (ref.read(authNotifierProvider) == AuthStatus.authenticated) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
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
          color: Color.fromRGBO(154, 141, 140, 1), // Color del texto del botón
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4), // Sombra más oscura
            spreadRadius: 4,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: SignInButton(
          Buttons.Google,
          text: 'Iniciar Sesión con Google',
          onPressed: () async {
            await ref.read(authNotifierProvider.notifier).signInWithGoogle();
            if (ref.read(authNotifierProvider) == AuthStatus.authenticated) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            }
          },
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

  bool _validateInputs(BuildContext context) {
    bool isValid = true;

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa un correo válido.')),
      );
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa la contraseña.')),
      );
      isValid = false;
    }

    return isValid;
  }
}
