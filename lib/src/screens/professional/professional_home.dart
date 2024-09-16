import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Drawer compartido

class ProfessionalHome extends StatefulWidget {
  @override
  _ProfessionalHomeState createState() => _ProfessionalHomeState();
}

class _ProfessionalHomeState extends State<ProfessionalHome> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController = TextEditingController(); // Número de documento
  final _licenseNumberController = TextEditingController(); // Matrícula

  String? _documentType; // Tipo de documento
  String? uid; // UID del usuario autenticado
  String? email; // Email del usuario autenticado
  bool _submitted = false;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _hasData = false;
  bool _isDocumentFieldsEditable = false; // Controlar la edición de los campos bloqueados

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Cargar los datos del usuario al iniciar la página
  }

  // Cargar los datos del usuario desde Firestore utilizando el UID
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      uid = user.uid;
      email = user.email;

      try {
        // Buscar los datos del usuario en Firestore utilizando el UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

          if (data != null) {
            setState(() {
              _nameController.text = data['name'] ?? '';
              _lastNameController.text = data['lastName'] ?? '';
              _addressController.text = data['address'] ?? '';
              _phoneController.text = data['phone'] ?? '';
              _documentNumberController.text = data['documentNumber'] ?? '';
              _licenseNumberController.text = data['n_matricula']?.toString() ?? ''; // Convertir el número de matrícula a string
              _documentType = data['documentType'] ?? 'DNI'; // Tipo de documento predeterminado

              _hasData = _checkMandatoryData(data); // Verificar que todos los datos obligatorios estén completos
              _submitted = true; // Marcar como enviado
              _isEditing = false;
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _isLoading = false; // Los datos no existen
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false; // Error al cargar los datos
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los datos del usuario')),
        );
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
        data['n_matricula'] != null &&
        data['documentType'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Profesional'),
      ),
      drawer: SharedDrawer(), // Utilizar el Drawer compartido
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Mostrar un spinner mientras se cargan los datos
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hasData && !_isEditing
                      ? _buildProfessionalInfo()
                      : _buildForm(),
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
            decoration: InputDecoration(labelText: 'Dirección del consultorio'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese la dirección del consultorio';
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
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _licenseNumberController,
                  decoration: InputDecoration(labelText: 'Número de matrícula'),
                  keyboardType: TextInputType.number,
                  enabled: _isDocumentFieldsEditable,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su número de matrícula';
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
    if (uid == null || uid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: El UID del usuario no es válido.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _nameController.text,
      'lastName': _lastNameController.text,
      'address': _addressController.text,
      'phone': _phoneController.text,
      'email': email,
      'documentType': _documentType,
      'documentNumber': _documentNumberController.text,
      'n_matricula': int.tryParse(_licenseNumberController.text) ?? 0, // Guardar matrícula como número
    });

    setState(() {
      _submitted = true;
      _hasData = true;
      _isEditing = false;
      _isDocumentFieldsEditable = false; // Deshabilitar edición de documentos después de guardar
    });
  }

  // Muestra la información después de que se ingresen o carguen los datos
  Widget _buildProfessionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dr. ${_nameController.text} ${_lastNameController.text}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Especialista en Psicología Clínica',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 10),
        Text(
          'Consultorio: ${_addressController.text}',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Teléfono: ${_phoneController.text}',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Tipo de Documento: $_documentType',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Número de Documento: ${_documentNumberController.text}',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Número de Matrícula: ${_licenseNumberController.text}',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Email: $email',
          style: TextStyle(fontSize: 16),
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
