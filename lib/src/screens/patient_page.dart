import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:async';

class PatientPage extends ConsumerStatefulWidget {
  final String email;

  PatientPage({required this.email});

  @override
  _PatientPageState createState() => _PatientPageState();
}

class _PatientPageState extends ConsumerState<PatientPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Controladores para los campos de texto
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedGender =
      'Masculino'; // Variable para almacenar el valor seleccionado
  bool _isEditing = false; // Variable para controlar el estado de edición
  bool _isLoading = false; // Variable para controlar el estado de carga

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _startReminderTimer();
  }

  void _checkAuthentication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserData();
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _ageController.dispose();
    _documentController.dispose();
    _emailController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _firstNameController.text = data['first_name'] ?? '';
            _lastNameController.text = data['last_name'] ?? '';
            _birthDateController.text = data['birth_date'] ?? '';
            _ageController.text = data['age']?.toString() ?? '';
            _documentController.text = data['document'] ?? '';
            _emailController.text = data['email'] ?? widget.email;
            _selectedGender = data['gender'] ?? 'Masculino';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos del usuario: $e')),
      );
    }
  }

  Future<void> _savePersonalInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final uid = user.uid;

          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'first_name': _firstNameController.text,
            'last_name': _lastNameController.text,
            'birth_date': _birthDateController.text,
            'age': int.parse(_ageController.text),
            'document': _documentController.text,
            'email': _emailController.text,
            'gender': _selectedGender,
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Información personal guardada')),
          );

          setState(() {
            _isEditing = false;
            _isLoading = false;
          });

          // Recargar la página para aplicar los cambios
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => PatientPage(email: widget.email)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Usuario no autenticado')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar información personal: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _enableEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _startReminderTimer() {
    Timer.periodic(Duration(minutes: 5), (timer) {
      if (!_isEditing && _hasIncompleteFields()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Por favor, complete los campos faltantes de información personal.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  bool _hasIncompleteFields() {
    return _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _birthDateController.text.isEmpty ||
        _documentController.text.isEmpty;
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = "${picked.toLocal()}".split(' ')[0];
        _ageController.text = _calculateAge(picked).toString();
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final welcomeName = _firstNameController.text.isNotEmpty
        ? _firstNameController.text
        : widget.email;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ventana de Paciente'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Bienvenido $welcomeName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('INFORMACIÓN PERSONAL'),
              onTap: () {
                Navigator.pop(context);
                _pageController.jumpToPage(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_back, color: Colors.blue),
              title: Text(
                'Volver a Inicio',
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(sessionProvider.notifier).logOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                ),
                child: Text(
                  'SALIR',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Bienvenido $welcomeName a la ventana de paciente',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  children: [
                    _buildPersonalInfoSection(),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INFORMACIÓN PERSONAL',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                  readOnly: _firstNameController.text.isNotEmpty && !_isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su nombre';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: 'Apellido'),
                  readOnly: _lastNameController.text.isNotEmpty && !_isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su apellido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _birthDateController,
                  decoration: InputDecoration(labelText: 'Fecha de Nacimiento'),
                  readOnly: !_isEditing, // Solo editable en modo edición
                  onTap: _isEditing
                      ? () => _selectBirthDate(context)
                      : null, // Solo permite seleccionar fecha en modo edición
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su fecha de nacimiento';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Edad'),
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _documentController,
                  decoration: InputDecoration(labelText: 'Documento'),
                  readOnly: _documentController.text.isNotEmpty && !_isEditing,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su documento';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Correo'),
                  readOnly: true,
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(labelText: 'Género'),
                  items: ['Masculino', 'Femenino', 'Otro'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: _isEditing
                      ? (newValue) {
                          setState(() {
                            _selectedGender = newValue!;
                          });
                        }
                      : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione su género';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Tooltip(
                      message: 'Guardar Información',
                      child: ElevatedButton.icon(
                        onPressed: _isEditing ? _savePersonalInfo : null,
                        icon: Icon(Icons.save_alt), // Icono más representativo
                        label: Text('Guardar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 20), // Espacio entre los botones
                    Tooltip(
                      message: 'Editar Información',
                      child: ElevatedButton.icon(
                        onPressed: _enableEditing,
                        icon: Icon(
                            Icons.edit_outlined), // Icono más representativo
                        label: Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
