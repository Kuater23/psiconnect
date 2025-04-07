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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Editar información personal",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 24),
          
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: "Nombre",
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 16),
          
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: "Apellido",
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 16),
          
          // Email is shown but not editable
          TextFormField(
            initialValue: _email,
            decoration: InputDecoration(
              labelText: "Correo electrónico",
              prefixIcon: Icon(Icons.email_outlined),
              filled: true,
              fillColor: Theme.of(context).disabledColor.withOpacity(0.1),
            ),
            enabled: false,
          ),
          SizedBox(height: 16),
          
          TextFormField(
            controller: _phoneNController,
            decoration: InputDecoration(
              labelText: "Teléfono",
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),
          
          TextFormField(
            controller: _dniController,
            decoration: InputDecoration(
              labelText: "DNI",
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          SizedBox(height: 16),
          
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: "Fecha de nacimiento",
                prefixIcon: Icon(Icons.calendar_today_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(),
              ),
              child: Text(
                _dob != null ? dateFormat.format(_dob!) : 'Seleccione fecha',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  icon: Icon(Icons.cancel),
                  label: Text("Cancelar"),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savePatientData,
                  icon: Icon(Icons.save),
                  label: Text("Guardar"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
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
