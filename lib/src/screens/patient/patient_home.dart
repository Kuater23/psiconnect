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
  final _documentNumberController =
      TextEditingController(); // Número de documento

  String? _documentType; // Tipo de documento
  String? uid; // UID del usuario autenticado
  bool _submitted = false;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _hasData = false;
  bool _isDocumentFieldsEditable =
      false; // Controlar la edición de los campos bloqueados

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
          _documentNumberController.text = data['documentNumber'] ?? '';
          _documentType =
              data['documentType'] ?? 'DNI'; // Tipo de documento predeterminado

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
        data['documentNumber'] != null &&
        data['documentType'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(2, 60, 67, 1), // Color de fondo
      appBar: AppBar(
        title: Text(
          'Información del Paciente',
          style: TextStyle(
              color: Color.fromRGBO(11, 191, 205, 1)), // Color del texto
        ),
        backgroundColor: Color.fromRGBO(1, 41, 46, 1), // Color de fondo
        iconTheme: IconThemeData(
          color: Color.fromRGBO(
              11, 191, 205, 1), // Color del ícono del menú hamburguesa
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
              child: CircularProgressIndicator(),
            ) // Mostrar un spinner mientras se cargan los datos
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
            'Complete la siguiente información',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
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
          SizedBox(height: 10),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: 'Apellido'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese su apellido';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
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
          SizedBox(height: 10),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'Teléfono'),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese su número de teléfono';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _documentType,
                  decoration: InputDecoration(labelText: 'Tipo de documento'),
                  items: ['DNI', 'Pasaporte', 'Otro'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: _isDocumentFieldsEditable
                      ? (newValue) {
                          setState(() {
                            _documentType = newValue;
                          });
                        }
                      : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione el tipo de documento';
                    }
                    return null;
                  },
                  disabledHint: Text(_documentType ?? 'DNI'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isDocumentFieldsEditable = !_isDocumentFieldsEditable;
                  });
                },
              )
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _documentNumberController,
                  decoration: InputDecoration(labelText: 'Número de documento'),
                  enabled: _isDocumentFieldsEditable,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su número de documento';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isDocumentFieldsEditable = !_isDocumentFieldsEditable;
                  });
                },
              )
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Si el formulario es válido, guardar los datos en Firestore
                _saveUserData();
              }
            },
            child: Text(_isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
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
        'documentType': _documentType,
        'documentNumber': _documentNumberController.text,
      }, SetOptions(merge: true));

      setState(() {
        _submitted = true;
        _hasData = true;
        _isEditing = false;
        _isDocumentFieldsEditable =
            false; // Deshabilitar edición de documentos después de guardar
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_nameController.text} ${_lastNameController.text}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(11, 191, 205, 1), // Color del texto
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Dirección: ${_addressController.text}',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromRGBO(11, 191, 205, 1), // Color del texto
          ),
        ),
        Text(
          'Teléfono: ${_phoneController.text}',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromRGBO(11, 191, 205, 1), // Color del texto
          ),
        ),
        Text(
          'Tipo de Documento: $_documentType',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromRGBO(11, 191, 205, 1), // Color del texto
          ),
        ),
        Text(
          'Número de Documento: ${_documentNumberController.text}',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromRGBO(11, 191, 205, 1), // Color del texto
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
          child: Text('Editar'),
        ),
      ],
    );
  }
}
