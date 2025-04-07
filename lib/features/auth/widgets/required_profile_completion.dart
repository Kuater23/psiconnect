// file: lib/features/auth/screens/required_profile_completion.dart

import 'package:Psiconnect/features/patient/models/patient_model.dart';
import 'package:Psiconnect/features/patient/providers/patient_providers.dart';
import 'package:Psiconnect/features/professional/models/professional_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:Psiconnect/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '/navigation/router.dart';
import 'package:Psiconnect/features/professional/providers/professional_providers.dart';

class RequiredProfileCompletion extends HookConsumerWidget {
  final String userRole;

  const RequiredProfileCompletion({
    Key? key,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _formKey = useState(GlobalKey<FormState>());
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final user = FirebaseAuth.instance.currentUser;
    final currentStep = useState(0);
    
    // Form controllers
    final firstNameController = useTextEditingController();
    final lastNameController = useTextEditingController();
    final dniController = useTextEditingController();
    final phoneController = useTextEditingController();
    final dobController = useTextEditingController();
    
    // Professional-only controllers
    final addressController = useTextEditingController();
    final licenseController = useTextEditingController(text: 'MN-');
    final specialityController = useTextEditingController();
    final breakDurationController = useTextEditingController(text: '30');
    final startTimeController = useTextEditingController(text: '09:00');
    final endTimeController = useTextEditingController(text: '17:00');
    
    // Professional-only state
    final workDays = useState<List<String>>(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']);
    final selectedSpeciality = useState<String>(specialityController.text.isNotEmpty 
      ? specialityController.text 
      : SpecialityConstants.psychologyTypes.first);
    
    // Define steps based on role
    final List<String> steps = userRole == 'professional' 
        ? ['Información personal', 'Información profesional', 'Horarios de trabajo']
        : ['Información personal'];
    
    // Helper method to load data from a document
    void _loadDataFromDoc(DocumentSnapshot doc, String role) {
      final data = doc.data() as Map<String, dynamic>;
      
      firstNameController.text = data['firstName'] ?? '';
      lastNameController.text = data['lastName'] ?? '';
      dniController.text = data['dni'] ?? '';
      phoneController.text = data['phoneN'] ?? '';
      
      if (data['dob'] != null) {
        final dob = (data['dob'] as Timestamp).toDate();
        dobController.text = DateFormat('yyyy-MM-dd').format(dob);
      }
      
      if (role == 'professional') {
        addressController.text = data['address'] ?? '';
        licenseController.text = data['license'] ?? 'MN-';
        specialityController.text = data['speciality'] ?? '';
        selectedSpeciality.value = data['speciality'] ?? SpecialityConstants.psychologyTypes.first;
        breakDurationController.text = data['breakDuration']?.toString() ?? '15';
        startTimeController.text = data['startTime'] ?? '09:00';
        endTimeController.text = data['endTime'] ?? '17:00';
        
        // Update to check both field names for backward compatibility
        if (data['workDays'] != null) {
          workDays.value = List<String>.from(data['workDays']);
        } else if (data['workDays'] != null) {
          workDays.value = List<String>.from(data['workDays']);
        }
      }
    }
    
    // Load user data
    Future<void> _loadUserData() async {
      if (user == null) return;
      
      try {
        isLoading.value = true;
        
        // Determine collection based on role
        String collection;
        if (userRole == 'professional') {
          collection = 'doctors';
        } else if (userRole == 'patient') {
          collection = 'patients';
        } else if (userRole == 'admin') {
          collection = 'admins';
        } else {
          // If role is invalid, let's check both collections to find the user
          final doctorDoc = await FirebaseFirestore.instance
              .collection('doctors')
              .doc(user.uid)
              .get();
              
          if (doctorDoc.exists) {
            _loadDataFromDoc(doctorDoc, 'professional');
            return;
          }
          
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(user.uid)
              .get();
              
          if (patientDoc.exists) {
            _loadDataFromDoc(patientDoc, 'patient');
            return;
          }
          
          // User not found in any collection
          errorMessage.value = 'User data not found';
          return;
        }
        
        print('Loading user data for uid: ${user.uid} from collection: $collection');
        
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          _loadDataFromDoc(doc, userRole);
        } else {
          errorMessage.value = 'User data not found in $collection collection';
        }
      } catch (e) {
        print('Error loading user data: $e');
        errorMessage.value = 'Error loading user data: $e';
      } finally {
        isLoading.value = false;
      }
    }
    
    // Load data on init
    useEffect(() {
      _loadUserData();
      return null;
    }, []);
    
    // Build personal information step
    Widget _buildPersonalInfoStep() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF01303A),
            ),
          ),
          const SizedBox(height: 24),
          
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // First name
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'El nombre es obligatorio' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Last name
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'El apellido es obligatorio' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // DNI
                  TextFormField(
                    controller: dniController,
                    decoration: const InputDecoration(
                      labelText: 'DNI *',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'El DNI es obligatorio' 
                        : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone number
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono *',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'El teléfono es obligatorio' 
                        : null,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date of birth
                  TextFormField(
                    controller: dobController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Nacimiento *',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      hintText: 'YYYY-MM-DD',
                    ),
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'La fecha de nacimiento es obligatoria' 
                        : null,
                    readOnly: true,
                    onTap: () async {
                      final initialDate = dobController.text.isNotEmpty 
                          ? DateTime.parse(dobController.text)
                          : DateTime(2000);
                          
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      
                      if (pickedDate != null) {
                        dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Build professional information step
    Widget _buildProfessionalInfoStep() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Profesional',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF01303A),
            ),
          ),
          const SizedBox(height: 24),
          
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Address
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección del Consultorio *',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => userRole == 'professional' && (value?.isEmpty ?? true) 
                        ? 'La dirección es obligatoria para profesionales' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // License number
                  TextFormField(
                    controller: licenseController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Licencia (MN-) *',
                      prefixIcon: Icon(Icons.card_membership),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => userRole == 'professional' && (value?.isEmpty ?? true || value == 'MN-') 
                        ? 'El número de licencia es obligatorio' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Speciality dropdown
                  DropdownButtonFormField<String>(
                    value: selectedSpeciality.value,
                    decoration: const InputDecoration(
                      labelText: 'Especialidad *',
                      prefixIcon: Icon(Icons.psychology),
                      border: OutlineInputBorder(),
                    ),
                    items: SpecialityConstants.psychologyTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        selectedSpeciality.value = newValue;
                        specialityController.text = newValue;
                      }
                    },
                    validator: (value) => userRole == 'professional' && (value == null || value.isEmpty)
                        ? 'La especialidad es obligatoria'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Build working hours step
    Widget _buildWorkingHoursStep() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horarios de Trabajo',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF01303A),
            ),
          ),
          const SizedBox(height: 24),
          
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Working hours
                  const Text(
                    'Horario de Atención', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Hora de Inicio *',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => userRole == 'professional' && (value?.isEmpty ?? true) 
                              ? 'La hora de inicio es obligatoria' 
                              : null,
                          readOnly: true,
                          onTap: () async {
                            final initialTime = TimeOfDay(
                              hour: int.tryParse(startTimeController.text.split(':')[0]) ?? 9,
                              minute: int.tryParse(startTimeController.text.split(':')[1]) ?? 0,
                            );
                            
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );
                            
                            if (pickedTime != null) {
                              startTimeController.text = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: endTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Hora de Fin *',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => userRole == 'professional' && (value?.isEmpty ?? true) 
                              ? 'La hora de fin es obligatoria' 
                              : null,
                          readOnly: true,
                          onTap: () async {
                            final initialTime = TimeOfDay(
                              hour: int.tryParse(endTimeController.text.split(':')[0]) ?? 17,
                              minute: int.tryParse(endTimeController.text.split(':')[1]) ?? 0,
                            );
                            
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );
                            
                            if (pickedTime != null) {
                              endTimeController.text = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Break duration
                  TextFormField(
                    controller: breakDurationController,
                    decoration: const InputDecoration(
                      labelText: 'Duración de Descanso (minutos) *',
                      prefixIcon: Icon(Icons.timer),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => userRole == 'professional' && (value?.isEmpty ?? true) 
                        ? 'La duración del descanso es obligatoria' 
                        : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  
                  // Working days
                  const Text(
                    'Días de Trabajo *', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDayChip(workDays, 'Monday', 'Lunes'),
                      _buildDayChip(workDays, 'Tuesday', 'Martes'),
                      _buildDayChip(workDays, 'Wednesday', 'Miércoles'),
                      _buildDayChip(workDays, 'Thursday', 'Jueves'),
                      _buildDayChip(workDays, 'Friday', 'Viernes'),
                      _buildDayChip(workDays, 'Saturday', 'Sábado'),
                      _buildDayChip(workDays, 'Sunday', 'Domingo'),
                    ],
                  ),
                  
                  if (workDays.value.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Debe seleccionar al menos un día de trabajo',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Build content based on current step
    Widget _buildStepContent() {
      if (userRole == 'professional') {
        switch (currentStep.value) {
          case 0: // Personal information
            return _buildPersonalInfoStep();
          case 1: // Professional information
            return _buildProfessionalInfoStep();
          case 2: // Working hours
            return _buildWorkingHoursStep();
          default:
            return _buildPersonalInfoStep();
        }
      } else {
        return _buildPersonalInfoStep();
      }
    }

    // Save profile function
    Future<void> _saveProfile() async {
      if (!_formKey.value.currentState!.validate()) {
        print('Form validation failed');
        return;
      }
      
      if (userRole == 'professional' && workDays.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debe seleccionar al menos un día de trabajo')),
        );
        return;
      }
      
      try {
        isLoading.value = true;
        errorMessage.value = null;
        
        if (user == null) {
          errorMessage.value = 'No user logged in.';
          return;
        }
        
        if (userRole == 'professional') {
          // Create professional model
          final professional = ProfessionalModel(
            uid: user.uid,
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            email: user.email ?? '',
            phoneN: phoneController.text.trim(),
            dni: dniController.text.trim(),
            address: addressController.text.trim(),
            license: licenseController.text.trim(),
            speciality: selectedSpeciality.value,
            dob: dobController.text.isNotEmpty 
                ? DateTime.parse(dobController.text)
                : null,
            workDays: workDays.value,
            startTime: startTimeController.text.trim(),
            endTime: endTimeController.text.trim(),
            breakDuration: int.tryParse(breakDurationController.text.trim()) ?? 30,
            profileCompleted: true,
          );
          
          // Save to Firestore using the model
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(user.uid)
              .update(professional.toFirestore());
        } else {
          // Create a PatientModel for patient users
          final patient = PatientModel(
            uid: user.uid,
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            email: user.email ?? '',
            phoneN: phoneController.text.trim(),
            dni: dniController.text.trim(),
            dob: dobController.text.isNotEmpty 
                ? DateTime.parse(dobController.text)
                : null,
            profileCompleted: true,
          );
          
          // Save to Firestore using the model
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user.uid)
              .update(patient.toFirestore());
        }
        
        // Navigate to appropriate screen
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
          
          Future.delayed(Duration(milliseconds: 500), () {
            if (context.mounted) {
              if (userRole == 'professional') {
                // Refresh the provider before navigating
                ref.read(professionalProvider.notifier).refresh().then((_) {
                  GoRouter.of(context).go(RoutePaths.professionalHome);
                });
              } else {
                // For patient, refresh patient provider
                ref.read(patientProfileProvider.notifier).refresh().then((_) {
                  GoRouter.of(context).go(RoutePaths.patientHome);
                });
              }
            }
          });
        }
      } catch (e) {
        errorMessage.value = 'Error al actualizar el perfil: ${e.toString()}';
      } finally {
        isLoading.value = false;
      }
    }

    // Navigation buttons based on current step
    Widget _buildNavigationButtons() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on first step)
          if (currentStep.value > 0)
            ElevatedButton.icon(
              onPressed: isLoading.value ? null : () {
                currentStep.value--;
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Anterior'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )
          else
            SizedBox(width: 120), // Spacer for alignment
          
          // Next/Save button
          ElevatedButton.icon(
            onPressed: isLoading.value ? null : () {
              if (currentStep.value == steps.length - 1) {
                // On last step, save the profile
                _saveProfile();
              } else if (_formKey.value.currentState!.validate()) {
                // Move to next step only if current step is valid
                currentStep.value++;
              }
            },
            icon: Icon(currentStep.value == steps.length - 1 ? Icons.save : Icons.arrow_forward),
            label: Text(currentStep.value == steps.length - 1 ? 'Guardar' : 'Siguiente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF01303A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    return WillPopScope(
      // Prevent going back
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('Completa tu Perfil'),
          backgroundColor: Color(0xFF01303A),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Remove back button
          elevation: 0,
        ),
        body: isLoading.value 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey.value,
                child: Column(
                  children: [
                    // Progress indicator and steps
                    Container(
                      color: Color(0xFF01303A),
                      padding: EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: LinearProgressIndicator(
                              value: (currentStep.value + 1) / steps.length,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paso ${currentStep.value + 1} de ${steps.length}',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  steps[currentStep.value],
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info message
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Completa tus datos para continuar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Esta información es necesaria para utilizar la aplicación.',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Error message if present
                          if (errorMessage.value != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      errorMessage.value!,
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Step content
                          _buildStepContent(),
                          
                          SizedBox(height: 32),
                          
                          // Navigation buttons
                          _buildNavigationButtons(),
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
  
  Widget _buildDayChip(ValueNotifier<List<String>> workDays, String day, String displayName) {
    final isSelected = workDays.value.contains(day);
    
    return FilterChip(
      label: Text(displayName),
      selected: isSelected,
      selectedColor: Color(0xFF01303A).withOpacity(0.15),
      checkmarkColor: Color(0xFF01303A),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Color(0xFF01303A) : Colors.grey[300]!,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Color(0xFF01303A) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        final updatedDays = List<String>.from(workDays.value);
        
        if (selected) {
          if (!updatedDays.contains(day)) {
            updatedDays.add(day);
          }
        } else {
          updatedDays.remove(day);
        }
        
        workDays.value = updatedDays;
      },
    );
  }
}