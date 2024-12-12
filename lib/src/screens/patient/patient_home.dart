import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientHome extends StatefulWidget {
  final VoidCallback toggleTheme;

  PatientHome({required this.toggleTheme});

  @override
  _PatientHomeState createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _addressController.text = data['address'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _dniController.text = data['dni'] ?? '';
          _emailController.text = data['email'] ?? '';
          _hasData = _checkMandatoryData(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay un usuario autenticado')),
      );
    }
  }

  bool _checkMandatoryData(Map<String, dynamic> data) {
    return data['name'] != null &&
        data['lastName'] != null &&
        data['address'] != null &&
        data['phone'] != null &&
        data['dni'] != null &&
        data['email'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasData
            ? 'Perfil de ${_nameController.text} ${_lastNameController.text}'
            : 'Información del Paciente'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(toggleTheme: widget.toggleTheme),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hasData && !_isEditing ? _buildPatientInfo() : _buildForm(),
                ],
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
          Text(
            'Complete la siguiente información',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildTextField(
            labelText: 'Nombre',
            controller: _nameController,
            validator: (value) =>
                value!.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          SizedBox(height: 10),
          _buildTextField(
            labelText: 'Apellido',
            controller: _lastNameController,
            validator: (value) =>
                value!.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          SizedBox(height: 10),
          _buildTextField(
            labelText: 'Dirección',
            controller: _addressController,
            validator: (value) =>
                value!.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          SizedBox(height: 10),
          _buildTextField(
            labelText: 'Teléfono',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value!.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          SizedBox(height: 10),
          _buildTextField(
            labelText: 'DNI',
            controller: _dniController,
            validator: (value) =>
                value!.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          SizedBox(height: 10),
          _buildTextField(
            labelText: 'Email',
            controller: _emailController,
            validator: (value) =>
                value!.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _saveUserData();
                }
              },
              icon: Icon(Icons.save, color: Colors.blueAccent),
              label: Text(
                _isEditing ? 'Actualizar' : 'Guardar',
                style: TextStyle(color: Colors.blueAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blueAccent),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text,
        'lastName': _lastNameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'dni': _dniController.text,
        'email': _emailController.text,
      }, SetOptions(merge: true));

      setState(() {
        _hasData = true;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos guardados correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario no autenticado')),
      );
    }
  }

  Widget _buildPatientInfo() {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blueAccent, size: 40),
                SizedBox(width: 10),
                Text(
                  '${_nameController.text} ${_lastNameController.text}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.blue), // Línea azul separadora
            SizedBox(height: 10),
            _buildInfoRow(
                Icons.location_on, 'Dirección: ${_addressController.text}'),
            _buildInfoRow(Icons.phone, 'Teléfono: ${_phoneController.text}'),
            _buildInfoRow(Icons.badge, 'DNI: ${_dniController.text}'),
            _buildInfoRow(Icons.email, 'Email: ${_emailController.text}'),
            SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                icon: Icon(Icons.edit, color: Colors.blueAccent),
                label: Text(
                  'Editar',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blueAccent),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
