import 'package:flutter/material.dart';
import 'package:Psiconnect/src/providers/auth_providers.dart'; // Proveedor de estado de autenticación.
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>(); // Clave del formulario para validaciones.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // Controla la visibilidad de la contraseña.

  @override
  void dispose() {
    // Liberar los controladores cuando el widget se destruya.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider); // Estado de autenticación.

    return Scaffold(
      backgroundColor: const Color.fromRGBO(2, 60, 67, 1),
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: const Color.fromRGBO(2, 60, 67, 1),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _buildContent(context),
          if (authState == AuthStatus.loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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
              const Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(11, 191, 205, 1),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Inicie Sesión para continuar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 300,
                child: Card(
                  color: const Color.fromRGBO(1, 40, 45, 1),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 20),
                          _buildTextFields(),
                          const SizedBox(height: 20),
                          _buildLoginButton(context),
                          const SizedBox(height: 10),
                          _buildGoogleLoginButton(context),
                          const SizedBox(height: 10),
                          _buildRegisterButton(context),
                        ],
                      ),
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
          borderRadius: BorderRadius.circular(20.0),
          child: Image.asset(
            'assets/images/logo.png',
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Bienvenido a Psiconnect',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        // Campo de Email.
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: const TextStyle(color: Color.fromRGBO(11, 191, 205, 1)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color.fromRGBO(11, 191, 205, 1)),
            ),
            prefixIcon: const Icon(Icons.email, color: Color.fromRGBO(11, 191, 205, 1)),
          ),
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Color.fromRGBO(11, 191, 205, 1)),
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Por favor, ingresa un correo válido.';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        // Campo de Contraseña.
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            labelStyle: const TextStyle(color: Color.fromRGBO(11, 191, 205, 1)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color.fromRGBO(11, 191, 205, 1)),
            ),
            prefixIcon: const Icon(Icons.lock, color: Color.fromRGBO(11, 191, 205, 1)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color.fromRGBO(11, 191, 205, 1),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          style: const TextStyle(color: Color.fromRGBO(11, 191, 205, 1)),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, ingresa la contraseña.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          await ref.read(authNotifierProvider.notifier).signInWithEmail(
                _emailController.text.trim(),
                _passwordController.text,
              );
          if (ref.read(authNotifierProvider) == AuthStatus.authenticated) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 10,
      ),
      child: const Text(
        'Iniciar Sesión',
        style: TextStyle(color: Color.fromRGBO(154, 141, 140, 1)),
      ),
    );
  }

  Widget _buildGoogleLoginButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            spreadRadius: 4,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: SignInButton(
          Buttons.Google,
          text: 'Iniciar Sesión con Google',
          onPressed: () async {
            await ref.read(authNotifierProvider.notifier).signInWithGoogle(role: '');
            if (ref.read(authNotifierProvider) == AuthStatus.authenticated) {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
      child: const Text(
        '¿Todavía no tienes una cuenta? Regístrate aquí',
        style: TextStyle(color: Color.fromRGBO(11, 191, 205, 1)),
      ),
    );
  }
}
