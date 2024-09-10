import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _chronicDiseasesController = TextEditingController();
  final TextEditingController _currentMedicationsController = TextEditingController();

  // Variable para almacenar el género seleccionado
  String _selectedGender = 'Masculino';

  // Variables para el calendario
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Función modularizada para guardar datos en Firestore
  Future<void> _saveData(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set(data, SetOptions(merge: true));
      _showSnackBar('Datos guardados correctamente');
    } else {
      _showSnackBar('Error: Usuario no autenticado');
    }
  }

  Future<void> _savePersonalInfo() async {
    if (_formKey.currentState!.validate()) {
      await _saveData({
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
        'gender': _genderController.text,
      });
    }
  }

  Future<void> _saveContactInfo() async {
    if (_formKey.currentState!.validate()) {
      await _saveData({
        'phone': _phoneController.text,
        'address': _addressController.text,
      });
    }
  }

  Future<void> _saveMedicalHistory() async {
    if (_formKey.currentState!.validate()) {
      await _saveData({
        'allergies': _allergiesController.text,
        'chronicDiseases': _chronicDiseasesController.text,
        'currentMedications': _currentMedicationsController.text,
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                'Bienvenido ${widget.email} a la ventana de paciente',
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
                _buildContactSection(),
                _buildMedicalHistorySection(),
                _buildCalendarSection(),
                _buildSessionsSection(),
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
          _buildDrawerItem('CONTACTO', 1),
          _buildDrawerItem('ANTECEDENTES MÉDICOS', 2),
          _buildDrawerItem('CALENDARIO', 3),
          _buildDrawerItem('MIS SESIONES', 4),
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
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'INFORMACIÓN PERSONAL',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su nombre';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Edad'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su edad';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(labelText: 'Género'),
              items: ['Masculino', 'Femenino', 'Otro'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedGender = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor seleccione su género';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePersonalInfo,
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'CONTACTO',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su teléfono';
                }
                return null;
              },
            ),
            TextFormField(
              controller: TextEditingController(text: widget.email),
              decoration: InputDecoration(labelText: 'Correo'),
              readOnly: true,
            ),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Dirección'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su dirección';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveContactInfo,
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistorySection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'ANTECEDENTES MÉDICOS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextFormField(
              controller: _allergiesController,
              decoration: InputDecoration(labelText: 'Alergias'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese sus alergias';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _chronicDiseasesController,
              decoration: InputDecoration(labelText: 'Enfermedades crónicas'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese sus enfermedades crónicas';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _currentMedicationsController,
              decoration: InputDecoration(labelText: 'Medicamentos actuales'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese sus medicamentos actuales';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveMedicalHistory,
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'CALENDARIO',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'Aquí van las sesiones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
