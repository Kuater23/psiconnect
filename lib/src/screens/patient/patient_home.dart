import 'package:Psiconnect/src/widgets/shared_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientPage extends StatefulWidget {
  final String email;

  PatientPage({required this.email});

  @override
  _PatientPageState createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dniController = TextEditingController(); // DNI
  final _emailController = TextEditingController(); // Email

  String? uid; // UID del usuario autenticado
  bool _submitted = false;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Cargar los datos del usuario al iniciar la página
  }

  // Cargar los datos del usuario desde Firestore utilizando el UID
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
          _dniController.text = data['dni'] ?? ''; // Cargar DNI
          _emailController.text = data['email'] ?? ''; // Cargar Email

          _hasData = _checkMandatoryData(
              data); // Verificar que todos los datos obligatorios estén completos
          _submitted = true; // Marcar como enviado
          _isEditing = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false; // Los datos no existen
        });
      }
    } else {
      setState(() {
        _isLoading = false; // No hay usuario autenticado
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay un usuario autenticado')),
      );
    }
  }

  // Verificar si todos los campos obligatorios están completos
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
      backgroundColor: Color.fromRGBO(
          2, 60, 67, 1), // Color base de Psiconnect para el fondo
      appBar: AppBar(
        title: Text('Información del Paciente'),
        backgroundColor: Color.fromRGBO(
            2, 60, 67, 1), // Color base de Psiconnect para el fondo
        titleTextStyle: TextStyle(
          color: Colors.white, // Color de texto blanco
          fontSize: 24, // Tamaño del texto
          fontWeight: FontWeight.bold, // Negrita para el texto
        ),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            },
          ),
        ],
      ),
      drawer: SharedDrawer(), // Utilizar el Drawer compartido
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(), // Mostrar un spinner mientras se cargan los datos
            )
          : Padding(
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

  // Formulario de ingreso o edición de datos
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete la información restante',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 20),
          _buildTextField(_dniController, 'DNI', 'Por favor ingrese su DNI'),
          SizedBox(height: 10),
          _buildTextField(
              _emailController, 'Email', 'Por favor ingrese su email'),
          SizedBox(height: 10),
          _buildTextField(
              _nameController, 'Nombre', 'Por favor ingrese su nombre'),
          SizedBox(height: 10),
          _buildTextField(
              _lastNameController, 'Apellido', 'Por favor ingrese su apellido'),
          SizedBox(height: 10),
          _buildTextField(_phoneController, 'Teléfono',
              'Por favor ingrese su número de teléfono',
              keyboardType: TextInputType.phone),
          SizedBox(height: 10),
          _buildTextField(_addressController, 'Dirección',
              'Por favor ingrese su dirección'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Si el formulario es válido, guardar los datos en Firestore
                _saveUserData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Color.fromRGBO(11, 191, 205, 1), // Color de fondo del botón
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 10, // Aumentar la sombra para el botón
            ),
            child: Text(
              _isEditing ? 'Actualizar' : 'Guardar',
              style: TextStyle(
                color: Colors.white, // Color del texto
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String labelText, String errorMessage,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorMessage;
        }
        return null;
      },
      style: TextStyle(color: Colors.white),
    );
  }

  // Guardar o actualizar los datos del usuario en Firestore
  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text,
        'lastName': _lastNameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'dni': _dniController.text, // Guardar DNI
        'email': _emailController.text, // Guardar Email
      }, SetOptions(merge: true));

      setState(() {
        _submitted = true;
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

  // Muestra la información después de que se ingresen o carguen los datos
  Widget _buildPatientInfo() {
    return Card(
      color: Color.fromRGBO(
          1, 40, 45, 1), // Color de fondo del contenedor del login
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_nameController.text} ${_lastNameController.text}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'Dirección: ${_addressController.text}',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            Text(
              'Teléfono: ${_phoneController.text}',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            Text(
              'DNI: ${_dniController.text}',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            Text(
              'Email: ${_emailController.text}',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight, // Mover el botón a la derecha
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(
                      11, 191, 205, 1), // Color de fondo del botón
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 10, // Aumentar la sombra para el botón
                ),
                child: Text(
                  'Editar',
                  style: TextStyle(
                    color: Colors.white, // Color del texto
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
