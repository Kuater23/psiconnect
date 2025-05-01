import 'package:Psiconnect/features/patient/models/patient_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/navigation/shared_drawer.dart';
import 'package:intl/intl.dart';

class PatientHome extends StatefulWidget {
  final VoidCallback toggleTheme;
  const PatientHome({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _PatientHomeState createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  bool _isLoading = true;
  bool _isEditing = false;
  String _errorMessage = '';

  // Controllers for editable fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();

  String _email = "";
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    // Clean up controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  // Load patient data from "patients" collection
  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay un usuario autenticado';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No hay un usuario autenticado")),
        );
        return;
      }

      String uid = user.uid;
      print('Loading patient data for uid: $uid'); // Debug log

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();

      if (doc.exists) {
        print('Patient document exists'); // Debug log
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        print('Patient data: $data'); // Debug log to see what we're getting

        if (mounted) {
          setState(() {
            _firstNameController.text = data['firstName'] ?? "";
            _lastNameController.text = data['lastName'] ?? "";
            _email = data['email'] ?? user.email ?? "";
            _phoneNController.text = data['phoneN'] ?? "";
            _dniController.text = data['dni'] ?? "";

            if (data['dob'] != null) {
              if (data['dob'] is Timestamp) {
                _dob = (data['dob'] as Timestamp).toDate();
              } else if (data['dob'] is String) {
                try {
                  _dob = DateTime.parse(data['dob']);
                } catch (e) {
                  print('Failed to parse dob string: ${e.toString()}');
                }
              }
            }
            _isLoading = false;
          });
        }
      } else {
        print('Patient document does not exist'); // Debug log

        // Check if user profile exists in the users collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          print('User document exists, creating patient record'); // Debug log
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Create a new patient document with user data
          await FirebaseFirestore.instance.collection('patients').doc(uid).set({
            'firstName': userData['firstName'] ?? '',
            'lastName': userData['lastName'] ?? '',
            'email': userData['email'] ?? user.email ?? '',
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Reload data
          if (mounted) {
            _loadPatientData();
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Datos del paciente no encontrados';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Datos del paciente no encontrados")),
            );
          }
        }
      }
    } catch (error) {
      print('Error loading patient data: ${error.toString()}'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar los datos: ${error.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar los datos")),
        );
      }
    }
  }

  // Save changes to "patients" collection
  Future<void> _savePatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        // Create a PatientModel with the updated values
        final patient = PatientModel(
          uid: uid,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _email,
          phoneN: _phoneNController.text,
          dni: _dniController.text,
          dob: _dob,
          profileCompleted: true,
        );

        // Save to Firestore using the model's toFirestore method
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(uid)
            .set(patient.toFirestore(), SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Datos guardados correctamente")),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No hay un usuario autenticado")),
          );
        }
      }
    } catch (error) {
      print('Error saving patient data: ${error.toString()}'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar los cambios")),
        );
      }
    }
  }

  // Select date of birth
  Future<void> _pickDate() async {
    DateTime initialDate = _dob ?? DateTime(2000, 1, 1);
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dob = picked;
      });
    }
  }

  // Display patient information
  Widget _buildDisplay() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        child: Text(
                          _firstNameController.text.isNotEmpty ? 
                            _firstNameController.text[0].toUpperCase() : 
                            "?",
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_firstNameController.text} ${_lastNameController.text}",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Paciente",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  
                  _infoRow(Icons.email_outlined, "Correo electrónico", _email),
                  _infoRow(Icons.phone_outlined, "Teléfono", _phoneNController.text),
                  _infoRow(Icons.badge_outlined, "DNI", _dniController.text),
                  _infoRow(
                    Icons.calendar_today_outlined, 
                    "Fecha de nacimiento", 
                    _dob != null ? dateFormat.format(_dob!) : 'No asignada'
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            icon: Icon(Icons.edit),
            label: Text("Editar información personal"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value.isEmpty ? "No asignado" : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w500,
                    color: value.isEmpty ? 
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4) : 
                      Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Form to edit patient information
  Widget _buildEditForm() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return SingleChildScrollView(
      child: Card(
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Text(
                  'Editar Información Personal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información personal - Section header
                  Text(
                    'Datos Personales',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Nombre y apellido en la misma fila
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditField(
                          controller: _firstNameController,
                          label: 'Nombre',
                          icon: Icons.person_outline,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildEditField(
                          controller: _lastNameController,
                          label: 'Apellido',
                          icon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Email no editable
                  _buildReadOnlyField(
                    value: _email,
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                  ),
                  SizedBox(height: 16),
                  
                  // DNI y teléfono en la misma fila
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditField(
                          controller: _dniController,
                          label: 'DNI',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildEditField(
                          controller: _phoneNController,
                          label: 'Teléfono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Fecha de nacimiento
                  Text(
                    'Fecha de Nacimiento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Selector de fecha con mejor UI
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Fecha de nacimiento',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _dob != null ? dateFormat.format(_dob!) : 'Seleccione fecha',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer con botones
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    child: Text('Cancelar'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _savePatientData,
                    child: Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper para construir campos de edición consistentes
  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 16),
      textCapitalization: keyboardType == TextInputType.text ? 
          TextCapitalization.words : TextCapitalization.none,
    );
  }

  // Widget para campos de solo lectura
  Widget _buildReadOnlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value.isEmpty ? "No asignado" : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mi Perfil"),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
            tooltip: "Cambiar tema",
          ),
        ],
      ),
      drawer: SharedDrawer(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  if (_errorMessage.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(_errorMessage, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPatientData,
                      child: Text("Reintentar"),
                    ),
                  ],
                ],
              ),
            )
          : (_isEditing ? _buildEditForm() : _buildDisplay()),
    );
  }
}
