import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';

class PatientFields {
  static const String dob = 'dob';
  static const String email = 'email';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String password = 'password';
  static const String phoneN = 'phoneN';
  static const String dni = 'dni';
  static const String uid = 'uid';
}

class PatientHome extends StatefulWidget {
  final VoidCallback toggleTheme;
  const PatientHome({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _PatientHomeState createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    _controllers = {
      PatientFields.firstName: TextEditingController(),
      PatientFields.lastName: TextEditingController(),
      PatientFields.dob: TextEditingController(),
      PatientFields.phoneN: TextEditingController(),
      PatientFields.dni: TextEditingController(),
      PatientFields.email: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('Firebase Data: $data'); // Debug
        
        setState(() {
          _controllers[PatientFields.firstName]?.text = data[PatientFields.firstName] ?? '';
          _controllers[PatientFields.lastName]?.text = data[PatientFields.lastName] ?? '';
          _controllers[PatientFields.dob]?.text = data[PatientFields.dob] ?? '';
          _controllers[PatientFields.phoneN]?.text = data[PatientFields.phoneN] ?? '';
          _controllers[PatientFields.dni]?.text = data[PatientFields.dni] ?? '';
          _controllers[PatientFields.email]?.text = data[PatientFields.email] ?? '';
          
          _hasData = _validateMandatoryData(data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error loading data: ${e.toString()}');
    }
  }

  bool _validateMandatoryData(Map<String, dynamic> data) {
    final requiredFields = [
      PatientFields.firstName,
      PatientFields.lastName,
      PatientFields.dob,
      PatientFields.phoneN,
      PatientFields.dni,
      PatientFields.email,
    ];
    return requiredFields.every((field) => 
      data[field]?.toString().isNotEmpty ?? false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(thickness: 1),
            _buildInfoDetails(),
            const SizedBox(height: 20),
            _buildEditButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.person, color: Colors.blue, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${_controllers[PatientFields.firstName]!.text} ${_controllers[PatientFields.lastName]!.text}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDetails() {
    final infoItems = {
      Icons.calendar_today: 'Fecha de nacimiento: ${_controllers[PatientFields.dob]!.text}',
      Icons.phone: 'Teléfono: ${_controllers[PatientFields.phoneN]!.text}',
      Icons.badge: 'DNI: ${_controllers[PatientFields.dni]!.text}',
      Icons.email: 'Email: ${_controllers[PatientFields.email]!.text}',
    };

    return Column(
      children: infoItems.entries
          .map((entry) => _buildInfoRow(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _isEditing = true),
        icon: const Icon(Icons.edit, color: Colors.blue),
        label: const Text('Editar', style: TextStyle(color: Colors.blue)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete su información',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ..._buildFormFields(),
          const SizedBox(height: 20),
          _buildSaveButton(),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final Map<String, Tuple2<String, TextInputType>> fieldConfigs = {
      PatientFields.firstName: Tuple2('Nombre', TextInputType.text),
      PatientFields.lastName: Tuple2('Apellido', TextInputType.text),
      PatientFields.dob: Tuple2('Fecha de Nacimiento', TextInputType.datetime),
      PatientFields.phoneN: Tuple2('Teléfono', TextInputType.phone),
      PatientFields.dni: Tuple2('DNI', TextInputType.text),
      PatientFields.email: Tuple2('Email', TextInputType.emailAddress),
    };

    return fieldConfigs.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildTextField(
          labelText: entry.value.item1,
          controller: _controllers[entry.key]!,
          keyboardType: entry.value.item2,
          validator: _getValidator(entry.key),
        ),
      );
    }).toList();
  }

  String? Function(String?) _getValidator(String field) {
    return (value) {
      if (value?.isEmpty ?? true) return 'Este campo es obligatorio';
      if (field == PatientFields.email) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value!)) return 'Email inválido';
      }
      if (field == PatientFields.phoneN) {
        final phoneRegex = RegExp(r'^\d{9,}$');
        if (!phoneRegex.hasMatch(value!)) return 'Teléfono inválido';
      }
      return null;
    };
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final userData = {
        PatientFields.firstName: _controllers[PatientFields.firstName]!.text.trim(),
        PatientFields.lastName: _controllers[PatientFields.lastName]!.text.trim(),
        PatientFields.dob: _controllers[PatientFields.dob]!.text.trim(),
        PatientFields.phoneN: _controllers[PatientFields.phoneN]!.text.trim(),
        PatientFields.dni: _controllers[PatientFields.dni]!.text.trim(),
        PatientFields.email: _controllers[PatientFields.email]!.text.trim(),
        PatientFields.uid: user.uid,
      };

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .update(userData);

      setState(() {
        _hasData = true;
        _isEditing = false;
      });
      _showSnackBar('Datos actualizados correctamente');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Widget _buildTextField({
    required String labelText,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _saveUserData,
        icon: const Icon(Icons.save, color: Colors.blue),
        label: Text(
          _isEditing ? 'Actualizar' : 'Guardar',
          style: const TextStyle(color: Colors.blue),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _hasData && !_isEditing ? _buildPatientInfo() : _buildForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _hasData
              ? 'Perfil de ${_controllers[PatientFields.firstName]!.text} ${_controllers[PatientFields.lastName]!.text}'
              : 'Información del Paciente',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(toggleTheme: widget.toggleTheme),
      body: _buildBody(),
    );
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  const Tuple2(this.item1, this.item2);
}