import 'package:flutter/material.dart';
import 'package:Psiconnect/src/providers/auth_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'login_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();
  final TextEditingController _nroMatriculaController = TextEditingController();

  bool _isProfessional = false; // Para controlar si el usuario es profesional
  bool _obscurePassword = true; // Para mostrar/ocultar contraseña

  @override
  Widget build(BuildContext context) {
    final authState =
        ref.watch(authNotifierProvider); // Escucha el estado de autenticación.

    return Scaffold(
      backgroundColor: Color.fromRGBO(2, 60, 67, 1), // Color base de Psiconnect
      appBar: AppBar(
        title: Text('Registro'),
        backgroundColor: Color.fromRGBO(2, 60, 67, 1), // Color del AppBar
        titleTextStyle: TextStyle(
          color: Colors.white, // Color de texto blanco
          fontSize: 24,
          fontWeight: FontWeight.bold,
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
          if (authState == AuthStatus.loading)
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
                1, 40, 45, 1), // Fondo del contenedor de registro
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
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
                  _buildRegisterButton(context, ref),
                  SizedBox(height: 10),
                  _buildGoogleRegisterButton(context, ref),
                  SizedBox(height: 20),
                  _buildLoginButton(context),
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
          controller: _nameController,
          labelText: 'Nombre',
          hintText: 'Ingresa tu nombre',
          icon: Icons.person,
        ),
        SizedBox(height: 16.0),
        _buildTextField(
          controller: _lastNameController,
          labelText: 'Apellido',
          hintText: 'Ingresa tu apellido',
          icon: Icons.person_outline,
        ),
        SizedBox(height: 16.0),
        _buildTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Ingresa tu email',
          icon: Icons.email,
        ),
        SizedBox(height: 16.0),
        _buildTextField(
          controller: _dniController,
          labelText: 'Número de DNI',
          hintText: 'Ingresa tu número de DNI',
          icon: Icons.perm_identity,
        ),
        SizedBox(height: 16.0),
        _buildTextField(
          controller: _passwordController,
          labelText: 'Contraseña',
          hintText: 'Ingresa tu contraseña',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Color.fromRGBO(11, 191, 205, 1), // Color del icono
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        SizedBox(height: 16.0),
        _buildTextField(
          controller: _rePasswordController,
          labelText: 'Re-Contraseña',
          hintText: 'Re-ingresa tu contraseña',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Color.fromRGBO(11, 191, 205, 1), // Color del icono
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        if (_isProfessional) ...[
          SizedBox(height: 16.0),
          _buildTextField(
            controller: _nroMatriculaController,
            labelText: 'Matrícula Nacional',
            hintText: 'Ingresa tu matrícula nacional',
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
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
            color: Color.fromRGBO(11, 191, 205, 1)), // Color del label
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide:
              BorderSide(color: Color.fromRGBO(11, 191, 205, 1)), // Borde
        ),
        prefixIcon: Icon(icon, color: Color.fromRGBO(11, 191, 205, 1)), // Icono
        suffixIcon: suffixIcon,
      ),
      style:
          TextStyle(color: Color.fromRGBO(11, 191, 205, 1)), // Color del texto
    );
  }

  Widget _buildRoleSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Paciente', style: TextStyle(color: Colors.white)),
        Switch(
          value: _isProfessional,
          onChanged: (value) {
            setState(() {
              _isProfessional = value;
            });
          },
        ),
        Text('Profesional', style: TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildRegisterButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        if (_validateInputs(context)) {
          String role = _isProfessional ? 'professional' : 'patient';
          print('Attempting to register user with role: $role');
          await ref.read(authNotifierProvider.notifier).registerWithEmail(
                name: _nameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                email: _emailController.text.trim(),
                dni: _dniController.text.trim(),
                password: _passwordController.text,
                role: role,
                n_matricula:
                    _isProfessional ? _nroMatriculaController.text.trim() : '',
              );
          if (ref.read(authNotifierProvider) == AuthStatus.authenticated) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          } else {
            print(
                'Registration failed: ${ref.read(authNotifierProvider.notifier).errorMessage}');
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Color de fondo del botón
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 10,
      ),
      child: Text(
        'Registrarse',
        style: TextStyle(
          color: Color.fromRGBO(154, 141, 140, 1), // Color del texto del botón
        ),
      ),
    );
  }

  Widget _buildGoogleRegisterButton(BuildContext context, WidgetRef ref) {
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
          text: 'Registrarse con Google',
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

  Widget _buildLoginButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      },
      child: Text(
        '¿Ya tienes una cuenta? Inicia sesión aquí',
        style: TextStyle(
            color: Color.fromRGBO(11, 191, 205, 1)), // Color del texto
      ),
    );
  }

  bool _validateInputs(BuildContext context) {
    bool isValid = true;

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa tu nombre.')),
      );
      isValid = false;
    }

    if (_lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa tu apellido.')),
      );
      isValid = false;
    }

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa un correo válido.')),
      );
      isValid = false;
    }

    if (_dniController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa tu número de DNI.')),
      );
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa la contraseña.')),
      );
      isValid = false;
    }

    if (_passwordController.text != _rePasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      isValid = false;
    }

    if (_isProfessional && _nroMatriculaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Por favor, completa toda la información requerida.')),
      );
      isValid = false;
    }

    return isValid;
  }
}
