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
  final TextEditingController _genderController = TextEditingController();

  // Variable para almacenar el género seleccionado
  String _selectedGender = 'Masculino';

  // Variable para almacenar el estado de edición
  bool _isEditing = false;

  // Variable para almacenar los campos incompletos
  List<String> _incompleteFields = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Función para cargar datos del usuario desde Firestore
  Future<void> _loadUserData() async {
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
          _emailController.text = data['email'] ?? '';
          _documentController.text = data['document'] ?? '';
          _birthDateController.text = data['birth_date'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _selectedGender = data['gender'] ?? 'Masculino';
          _genderController.text = _selectedGender;

          // Verificar campos incompletos
          _checkIncompleteFields();
        });
      }
    }
  }

  // Función para verificar campos incompletos
  void _checkIncompleteFields() {
    _incompleteFields.clear();
    if (_firstNameController.text.isEmpty) _incompleteFields.add('Nombre');
    if (_lastNameController.text.isEmpty) _incompleteFields.add('Apellido');
    if (_emailController.text.isEmpty) _incompleteFields.add('Correo');
    if (_documentController.text.isEmpty) _incompleteFields.add('Documento');
    if (_birthDateController.text.isEmpty)
      _incompleteFields.add('Fecha de Nacimiento');
    if (_ageController.text.isEmpty) _incompleteFields.add('Edad');
    if (_genderController.text.isEmpty) _incompleteFields.add('Género');
  }

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
      _genderController.text =
          _selectedGender; // Asegurarse de que el controlador de género se actualice
      await _saveData({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'document': _documentController.text,
        'birth_date': _birthDateController.text,
        'age': int.parse(_ageController.text),
        'gender': _genderController.text,
      });
      setState(() {
        _isEditing = false;
        _checkIncompleteFields(); // Verificar campos incompletos después de guardar
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _calculateAge();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definir el color con los valores proporcionados
    final Color primaryColor = Color.fromARGB(255, 1, 40, 45);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Menú Paciente'), // Cambiado de "Ventana de Paciente" a "Menú Paciente"
      ),
      drawer: _buildDrawer(primaryColor),
      body: SafeArea(
        child: Container(
          color: Colors.grey[200], // Color de fondo para diferenciar la sección
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_incompleteFields.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Complete la siguiente información: ${_incompleteFields.join(', ')}',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(Color primaryColor) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Text(
              'Menú Paciente', // Cambiado a "Menú Paciente"
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerItem('INFORMACIÓN PERSONAL', 0),
          ListTile(
            leading: Icon(Icons.arrow_back, color: primaryColor),
            title: Text(
              'Volver a Inicio',
              style: TextStyle(color: primaryColor),
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
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(sessionProvider.notifier).logOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.symmetric(vertical: 15.0),
              ),
              icon: Icon(Icons.logout,
                  color: Colors
                      .white), // Icono de deslogueo con el color especificado
              label: Text(
                'Cerrar Sesión',
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
    final genderItems = ['Masculino', 'Femenino', 'Otro'];
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
                  onTap: () {
                    if (_isEditing) {
                      _selectDate(context);
                    }
                  },
                  readOnly: true,
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
                  value: genderItems.contains(_selectedGender)
                      ? _selectedGender
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Género',
                    icon: Icon(Icons.wc),
                  ),
                  items: genderItems.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: _isEditing
                      ? (newValue) {
                          setState(() {
                            _selectedGender = newValue!;
                            _genderController.text = newValue;
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
