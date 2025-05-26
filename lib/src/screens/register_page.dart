import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nroMatriculaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedSpecialty;
  
  bool _isProfessional = false;
  bool _obscurePassword = true;
  
  final List<String> _specialties = [
    "Psicología Clínica",
    "Psicología Educativa",
    "Psicología Organizacional",
    "Psicología Social",
    "Psicología Forense"
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(2, 60, 67, 1),
      appBar: AppBar(
        title: const Text('Registro'),
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
        ],
      ),
    );
  }
  
  Widget _buildLogo() {
    return Container(
      height: 100,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    String? prefixText,
    String? Function(String?)? validator,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        prefixText: prefixText,
        counterText: "",
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      validator: validator,
    );
  }
  
  Widget _buildDatePickerField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
          setState(() {
            _dobController.text = formattedDate;
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'Fecha de nacimiento',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
  
  Widget _buildRegisterButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () async {
        if (_isProfessional) {
          if (_nroMatriculaController.text.trim().length != 7) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("La matrícula debe tener exactamente 7 dígitos.")),
            );
            return;
          }
          if (_dniController.text.trim().length < 7) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("El DNI debe tener al menos 7 caracteres.")),
            );
            return;
          }
          if (_phoneController.text.trim().length > 15) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("El número de teléfono debe tener máximo 15 caracteres.")),
            );
            return;
          }
        }
  
        try {
          final UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          final String uid = userCredential.user!.uid;
  
          Map<String, dynamic> userData = {
            'firstName': _nameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'dob': _dobController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'uid': uid,
          };
  
          if (_isProfessional) {
            userData.addAll({
              'specialty': _selectedSpecialty,
              'phoneN': _phoneController.text.trim(),
              'license': "MN-" + _nroMatriculaController.text.trim(),
              'dni': _dniController.text.trim(),
            });
          }
  
          final String collectionName = _isProfessional ? 'doctors' : 'patients';
  
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(uid)
              .set(userData);
  
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al registrarse: $e")),
          );
        }
      },
      child: const Text(
        'Registrarse',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      child: const Text(
        '¿Ya tienes una cuenta? Inicia sesión aquí',
        style: TextStyle(
          color: Color.fromRGBO(11, 191, 205, 1),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildGoogleRegisterButton(BuildContext context) {
    return SignInButton(
      Buttons.Google,
      text: "Registrarse con Google",
      onPressed: () async {
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser == null) return;
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          final String uid = userCredential.user!.uid;
  
          String firstName = '';
          String lastName = '';
          if (googleUser.displayName != null) {
            List<String> nameParts = googleUser.displayName!.split(' ');
            if (nameParts.isNotEmpty) {
              firstName = nameParts.first;
              if (nameParts.length > 1) {
                lastName = nameParts.sublist(1).join(' ');
              }
            }
          }
  
          Map<String, dynamic> userData = {
            'first': firstName,
            'last': lastName,
            'age': _dobController.text.trim(),
            'email': googleUser.email,
            'password': 'google',
            'uid': uid,
          };
  
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(uid)
              .set(userData);
  
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error con Google: $e")),
          );
        }
      },
    );
  }
  
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSpecialty,
          hint: const Text(
            'Seleccionar especialidad',
            style: TextStyle(color: Colors.white70),
          ),
          isExpanded: true,
          dropdownColor: const Color.fromRGBO(1, 40, 45, 1),
          style: const TextStyle(color: Colors.white),
          items: _specialties.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedSpecialty = newValue;
            });
          },
        ),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 350,
          child: Card(
            color: const Color.fromRGBO(1, 40, 45, 1),
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
                  const SizedBox(height: 20),
                  _isProfessional ? _buildProfessionalForm() : _buildPatientForm(),
                  const SizedBox(height: 20),
                  _buildRoleSwitch(),
                  const SizedBox(height: 20),
                  if (!_isProfessional) ...[
                    _buildGoogleRegisterButton(context),
                    const SizedBox(height: 20),
                  ],
                  _buildRegisterButton(context),
                  const SizedBox(height: 10),
                  _buildLoginButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPatientForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          labelText: 'Nombre',
          icon: Icons.person,
        ),
        const SizedBox(height: 16.0),
        _buildTextField(
          controller: _lastNameController,
          labelText: 'Apellido',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16.0),
        _buildDatePickerField(),
        const SizedBox(height: 16.0),
        _buildTextField(
          controller: _emailController,
          labelText: 'Email',
          icon: Icons.email,
        ),
        const SizedBox(height: 16.0),
        _buildTextField(
          controller: _passwordController,
          labelText: 'Contraseña',
          icon: Icons.lock,
          obscureText: _obscurePassword,
        ),
      ],
    );
  }
  
  Widget _buildProfessionalForm() {
    return Column(
      children: [
        _buildPatientForm(),
        const SizedBox(height: 16.0),
        _buildDropdown(),
        const SizedBox(height: 16.0),
        _buildTextField(
          controller: _phoneController,
          labelText: 'Número de Teléfono',
          icon: Icons.phone,
          maxLength: 15,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16.0),
        _buildTextField(
          controller: _nroMatriculaController,
          labelText: 'Matrícula Nacional',
          icon: Icons.badge,
          prefixText: 'MN-',
          maxLength: 7,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16.0),
        _buildTextField(
          controller: _dniController,
          labelText: 'DNI',
          icon: Icons.perm_identity,
        ),
      ],
    );
  }
  
  Widget _buildRoleSwitch() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Paciente', 
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        )
      ),
      const SizedBox(width: 8), // Add spacing
      Switch(
        value: _isProfessional,
        onChanged: (value) {
          setState(() {
            _isProfessional = value;
            if (!value) {
              _selectedSpecialty = null;
              _nroMatriculaController.clear();
              _phoneController.clear();
              _dniController.clear();
            }
          });
        },
        activeColor: Colors.white, // Color of the thumb when active
        activeTrackColor: Colors.teal, // Color of the track when active
        inactiveThumbColor: Colors.white, // Color of the thumb when inactive
        inactiveTrackColor: Colors.grey.withOpacity(0.5), // Color of the track when inactive
      ),
      const SizedBox(width: 8), // Add spacing
      const Text(
        'Profesional', 
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        )
      ),
    ],
  );
}
}