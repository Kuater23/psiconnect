import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  // Variable para almacenar el género seleccionado
  String _selectedGender = 'Masculino';

  // Variable para almacenar el estado de edición
  bool _isEditing = false;

  // Función modularizada para guardar datos en Firestore
  Future<void> _saveData(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
      _showSnackBar('Datos guardados correctamente');
    } else {
      _showSnackBar('Error: Usuario no autenticado');
    }
  }

  Future<void> _savePersonalInfo() async {
    if (_formKey.currentState!.validate()) {
      await _saveData({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'document': _documentController.text,
        'birth_date': _birthDateController.text,
        'age': int.parse(_ageController.text),
        'gender': _genderController.text,
        'role': _roleController.text,
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _calculateAge() {
    if (_birthDateController.text.isNotEmpty) {
      DateTime birthDate =
          DateFormat('yyyy-MM-dd').parse(_birthDateController.text);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      _ageController.text = age.toString();
    }
  }

  String _getWelcomeMessage() {
    if (_firstNameController.text.isNotEmpty) {
      return 'Bienvenido ${_firstNameController.text} a la ventana de paciente';
    } else {
      return 'Bienvenido a la ventana de paciente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ventana de Paciente'),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                _getWelcomeMessage(),
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
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Bienvenido ${widget.email}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerItem('INFORMACIÓN PERSONAL', 0),
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
    );
  }

  ListTile _buildDrawerItem(String title, int pageIndex) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _pageController.jumpToPage(pageIndex);
      },
    );
  }

  Widget _buildPersonalInfoSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
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
                Divider(),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    icon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su nombre';
                    }
                    return null;
                  },
                  enabled: _isEditing,
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    icon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su apellido';
                    }
                    return null;
                  },
                  enabled: _isEditing,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    icon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su correo';
                    }
                    return null;
                  },
                  enabled: _isEditing,
                ),
                TextFormField(
                  controller: _documentController,
                  decoration: InputDecoration(
                    labelText: 'Documento',
                    icon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su documento';
                    }
                    return null;
                  },
                  enabled: _isEditing,
                ),
                TextFormField(
                  controller: _birthDateController,
                  decoration: InputDecoration(
                    labelText: 'Fecha de Nacimiento (yyyy-MM-dd)',
                    icon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su fecha de nacimiento';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _calculateAge();
                  },
                  enabled: _isEditing,
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Edad',
                    icon: Icon(Icons.cake),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su edad';
                    }
                    return null;
                  },
                  enabled: _isEditing,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Género',
                    icon: Icon(Icons.wc),
                  ),
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
                TextFormField(
                  controller: _roleController,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    icon: Icon(Icons.work),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su rol';
                    }
                    return null;
                  },
                  enabled: _isEditing,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isEditing ? _savePersonalInfo : null,
                      icon: Icon(Icons.save),
                      label: Text('Guardar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleEditing,
                      icon: Icon(Icons.edit),
                      label: Text('Editar'),
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
