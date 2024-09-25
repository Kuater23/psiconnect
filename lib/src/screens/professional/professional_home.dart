import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';
import 'package:Psiconnect/src/helpers/time_format_helper.dart'; // Integración con el helper de formato de tiempo
import 'package:Psiconnect/src/helpers/validation_helper.dart'; // Integración con el helper de validaciones
import 'package:Psiconnect/src/service/firestore_service.dart'; // Integración con el servicio Firestore

class ProfessionalHome extends StatefulWidget {
  final VoidCallback toggleTheme; // Añadir el parámetro toggleTheme

  // Constructor para aceptar el toggleTheme
  ProfessionalHome({required this.toggleTheme});

  @override
  _ProfessionalHomeState createState() => _ProfessionalHomeState();
}

class _ProfessionalHomeState extends State<ProfessionalHome> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController =
      TextEditingController(); // Número de documento
  final _licenseNumberController = TextEditingController(); // Matrícula
  final List<String> _selectedDays = []; // Días seleccionados
  TimeOfDay? _startTime; // Hora de inicio
  TimeOfDay? _endTime; // Hora de fin

  String? _documentType; // Tipo de documento
  String? uid; // UID del usuario autenticado
  String? email; // Email del usuario autenticado
  bool _submitted = false;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _hasData = false;
  bool _isDocumentFieldsEditable =
      false; // Controlar la edición de los campos bloqueados

  final FirestoreService _firestoreService =
      FirestoreService(); // Integración del servicio Firestore

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
        // Usar FirestoreService para obtener los datos del usuario
        final data = await _firestoreService.getUserData(uid!);

        if (data != null) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _lastNameController.text = data['lastName'] ?? '';
            _addressController.text = data['address'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _documentNumberController.text = data['documentNumber'] ?? '';
            _licenseNumberController.text =
                data['n_matricula']?.toString() ?? '';
            _documentType = data['documentType'] ?? 'DNI';

            // Cargar disponibilidad si existe
            if (data.containsKey('availability')) {
              Map<String, dynamic> availability = data['availability'];
              _selectedDays
                  .addAll(List<String>.from(availability['days'] ?? []));
              _startTime = TimeFormatHelper.parseTime(
                  availability['start_time'] ??
                      '09:00'); // Usar helper para el formato de hora
              _endTime = TimeFormatHelper.parseTime(
                  availability['end_time'] ?? '17:00');
            }

            _hasData = ValidationHelper.checkMandatoryData(
                data); // Usar helper para verificar datos obligatorios
            _submitted = true;
            _isEditing = false;
            _isLoading = false;
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Profesional'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6), // Icono de alternar tema
            onPressed:
                widget.toggleTheme, // Llama a la función toggleTheme pasada
          ),
        ],
      ),
      drawer: SharedDrawer(), // Utilizar el Drawer compartido
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(), // Mostrar un spinner mientras se cargan los datos
            )
          : SingleChildScrollView(
              // Envolver el contenido en un SingleChildScrollView
              child: Padding(
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
            validator: (value) => ValidationHelper.validateNotEmpty(
                value, 'nombre'), // Usar helper para validación
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: 'Apellido'),
            validator: (value) => ValidationHelper.validateNotEmpty(
                value, 'apellido'), // Usar helper para validación
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(labelText: 'Dirección del consultorio'),
            validator: (value) => ValidationHelper.validateNotEmpty(
                value, 'dirección'), // Usar helper para validación
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'Teléfono'),
            keyboardType: TextInputType.phone,
            validator: (value) => ValidationHelper.validateNotEmpty(
                value, 'teléfono'), // Usar helper para validación
          ),
          SizedBox(height: 10),

          // Campos reintroducidos para editar el tipo de documento y el DNI
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
                  validator: (value) => ValidationHelper.validateNotEmpty(value,
                      'tipo de documento'), // Usar helper para validación
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
                  validator: (value) => ValidationHelper.validateNotEmpty(value,
                      'número de documento'), // Usar helper para validación
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

          // Selector de días disponibles
          Text('Días Disponibles',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            children: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
                .map((day) => CheckboxListTile(
                      title: Text(day),
                      value: _selectedDays.contains(day),
                      onChanged: (isSelected) {
                        setState(() {
                          if (isSelected ?? false) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          SizedBox(height: 10),

          // Campos reintroducidos para editar el tipo de documento y el DNI
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
                  validator: (value) => ValidationHelper.validateNotEmpty(value,
                      'tipo de documento'), // Usar helper para validación
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
              ),
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
                  validator: (value) => ValidationHelper.validateNotEmpty(value,
                      'número de documento'), // Usar helper para validación
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isDocumentFieldsEditable = !_isDocumentFieldsEditable;
                  });
                },
              ),
            ],
          ),

          SizedBox(height: 10),

          // Selector de días disponibles
          Text('Días Disponibles',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            children: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
                .map((day) => CheckboxListTile(
                      title: Text(day),
                      value: _selectedDays.contains(day),
                      onChanged: (isSelected) {
                        setState(() {
                          if (isSelected ?? false) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          SizedBox(height: 10),

          // Selector de hora de inicio
          Text('Hora de Inicio', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: Text(_startTime != null
                ? TimeFormatHelper.formatTimeIn24Hours(
                    _startTime!) // Usar helper para formato de hora
                : 'Seleccione la hora de inicio'),
            trailing: Icon(Icons.access_time),
            onTap: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: _startTime ?? TimeOfDay(hour: 9, minute: 0),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _startTime = picked;
                });
              }
            },
          ),
          SizedBox(height: 10),

          // Selector de hora de fin
          Text('Hora de Fin', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: Text(_endTime != null
                ? TimeFormatHelper.formatTimeIn24Hours(
                    _endTime!) // Usar helper para formato de hora
                : 'Seleccione la hora de fin'),
            trailing: Icon(Icons.access_time),
            onTap: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: _endTime ?? TimeOfDay(hour: 17, minute: 0),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _endTime = picked;
                });
              }
            },
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

    // Usar FirestoreService para actualizar los datos del usuario
    await _firestoreService.updateUserData(
      uid!,
      _nameController.text,
      _lastNameController.text,
      _addressController.text,
      _phoneController.text,
      email,
      _documentType,
      _documentNumberController.text,
      int.tryParse(_licenseNumberController.text) ?? 0,
      _selectedDays,
      _startTime != null
          ? TimeFormatHelper.formatTimeIn24Hours(_startTime!)
          : '09:00',
      _endTime != null
          ? TimeFormatHelper.formatTimeIn24Hours(_endTime!)
          : '17:00',
    );

    setState(() {
      _submitted = true;
      _hasData = true;
      _isEditing = false;
      _isDocumentFieldsEditable =
          false; // Deshabilitar edición de documentos después de guardar
    });
  }

  // Muestra la información después de que se ingresen o carguen los datos
  Widget _buildProfessionalInfo() {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. ${_nameController.text} ${_lastNameController.text}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Especialista en Psicología Clínica',
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            Divider(),
            _buildInfoRow(
                Icons.location_on, 'Consultorio: ${_addressController.text}'),
            _buildInfoRow(Icons.phone, 'Teléfono: ${_phoneController.text}'),
            _buildInfoRow(Icons.badge, 'Tipo de Documento: $_documentType'),
            _buildInfoRow(Icons.perm_identity,
                'Número de Documento: ${_documentNumberController.text}'),
            _buildInfoRow(Icons.account_balance,
                'Número de Matrícula: ${_licenseNumberController.text}'),
            _buildInfoRow(Icons.email, 'Email: $email'),

            // Formatear y mostrar la disponibilidad en formato 24 horas
            _buildInfoRow(
              Icons.calendar_today,
              'Disponibilidad: ${_selectedDays.join(', ')} de ${_startTime != null ? TimeFormatHelper.formatTimeIn24Hours(_startTime!) : '09:00'} a ${_endTime != null ? TimeFormatHelper.formatTimeIn24Hours(_endTime!) : '17:00'}',
            ),

            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                child: Text('Editar'),
                style: ElevatedButton.styleFrom(
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
