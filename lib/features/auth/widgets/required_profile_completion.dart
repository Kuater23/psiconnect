// file: lib/features/auth/screens/required_profile_completion.dart

import 'package:Psiconnect/features/auth/providers/session_provider.dart';
import 'package:Psiconnect/features/patient/models/patient_model.dart';
import 'package:Psiconnect/features/patient/providers/patient_providers.dart';
import 'package:Psiconnect/features/patient/services/patient_service.dart';
import 'package:Psiconnect/features/professional/models/professional_model.dart';
import 'package:Psiconnect/features/professional/services/professional_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:Psiconnect/core/constants/app_constants.dart';
import '/navigation/router.dart';
import 'package:Psiconnect/features/professional/providers/professional_providers.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/error_logger.dart';
import '../../../core/utils/validation_helper.dart';

class RequiredProfileCompletion extends HookConsumerWidget {
  final String userRole;

  const RequiredProfileCompletion({
    Key? key,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useState(GlobalKey<FormState>());
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final user = FirebaseAuth.instance.currentUser;
    final currentStep = useState(0);
    final navigationService = NavigationService();
    
    // Services
    final patientService = PatientService();
    final professionalService = ProfessionalService();
    
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
    final workDays = useState<List<String>>([
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ]);
    final selectedSpeciality = useState<String>(
      specialityController.text.isNotEmpty
          ? specialityController.text
          : SpecialityConstants.psychologyTypes.first
    );
    
    // Define steps based on role
    final List<String> steps = userRole == 'professional'
        ? ['Información personal', 'Información profesional', 'Horarios de trabajo']
        : ['Información personal'];
    
    // Load user data
    Future<void> loadUserData() async {
      if (user == null) return;
      
      try {
        isLoading.value = true;
        errorMessage.value = null;

        if (userRole == 'professional') {
          final professional = await professionalService.getProfessional(user.uid);
          
          if (professional != null) {
            firstNameController.text = professional.firstName ?? '';
            lastNameController.text = professional.lastName ?? '';
            dniController.text = professional.dni ?? '';
            phoneController.text = professional.phoneN ?? '';
            
            if (professional.birthDate != null) {
              dobController.text = DateFormat('yyyy-MM-dd').format(professional.birthDate!);
            }
            
            addressController.text = professional.consultingAddress ?? '';
            licenseController.text = professional.licenseNumber ?? 'MN-';
            specialityController.text = professional.speciality ?? '';
            selectedSpeciality.value = professional.speciality ?? SpecialityConstants.psychologyTypes.first;
            
            // Cargar disponibilidad si existe
            if (professional.availability != null) {
              final availability = professional.availability!;
              
              // Extraer días de trabajo
              if (availability.containsKey('workDays')) {
                workDays.value = List<String>.from(availability['workDays']);
              }
              
              // Extraer horarios
              if (availability.containsKey('startTime')) {
                startTimeController.text = availability['startTime'] ?? '09:00';
              }
              if (availability.containsKey('endTime')) {
                endTimeController.text = availability['endTime'] ?? '17:00';
              }
              if (availability.containsKey('breakDuration')) {
                breakDurationController.text = availability['breakDuration'].toString();
              }
            }
          }
        } else {
          final patient = await patientService.getPatient(user.uid);
          
          if (patient != null) {
            firstNameController.text = patient.firstName ?? '';
            lastNameController.text = patient.lastName ?? '';
            dniController.text = patient.dni ?? '';
            phoneController.text = patient.phoneN ?? '';
            
            if (patient.birthDate != null) {
              dobController.text = DateFormat('yyyy-MM-dd').format(patient.birthDate!);
            }
          }
        }
      } catch (e, st) {
        ErrorLogger.logError('Error cargando datos del usuario', e, st);
        errorMessage.value = 'Error al cargar los datos: ${e.toString()}';
        navigationService.showError('Error al cargar los datos');
      } finally {
        isLoading.value = false;
      }
    }
    
    // Load data on init
    useEffect(() {
      loadUserData();
      return null;
    }, []);
    
    // Build personal information step
    Widget buildPersonalInfoStep() {
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
                    validator: (value) => ValidationHelper.validateRequired(
                      value,
                      fieldName: 'El nombre',
                    ),
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
                    validator: (value) => ValidationHelper.validateRequired(
                      value,
                      fieldName: 'El apellido',
                    ),
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
                    validator: ValidationHelper.validateDNI,
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
                    validator: ValidationHelper.validatePhone,
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
                    validator: (value) => ValidationHelper.validateDate(
                      value,
                      fieldName: 'La fecha de nacimiento',
                    ),
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
    Widget buildProfessionalInfoStep() {
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
                    validator: (value) => ValidationHelper.validateRequired(
                      value,
                      fieldName: 'La dirección',
                    ),
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
                    validator: (value) {
                      if (value == null || value.isEmpty || value == 'MN-') {
                        return 'El número de licencia es obligatorio';
                      }
                      if (!value.startsWith('MN-')) {
                        return 'El formato debe ser MN-XXXXX';
                      }
                      return null;
                    },
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
                    validator: (value) => ValidationHelper.validateRequired(
                      value,
                      fieldName: 'La especialidad',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Build working hours step
    Widget buildWorkingHoursStep() {
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
                          validator: (value) => ValidationHelper.validateRequired(
                            value,
                            fieldName: 'La hora de inicio',
                          ),
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
                              startTimeController.text =
                                  '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
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
                          validator: (value) => ValidationHelper.validateRequired(
                            value,
                            fieldName: 'La hora de fin',
                          ),
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
                              endTimeController.text =
                                  '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
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
                    validator: (value) => ValidationHelper.combineValidators([
                      (v) => ValidationHelper.validateRequired(v, fieldName: 'La duración del descanso'),
                      ValidationHelper.validateNumeric,
                      (v) => ValidationHelper.validateRange(v, 5, 120, fieldName: 'La duración'),
                    ])(value),
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
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
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
    Widget buildStepContent() {
      if (userRole == 'professional') {
        switch (currentStep.value) {
          case 0:
            return buildPersonalInfoStep();
          case 1:
            return buildProfessionalInfoStep();
          case 2:
            return buildWorkingHoursStep();
          default:
            return buildPersonalInfoStep();
        }
      } else {
        return buildPersonalInfoStep();
      }
    }

    // Save profile function
    Future<void> saveProfile() async {
      if (!formKey.value.currentState!.validate()) {
        ErrorLogger.warning('Validación del formulario fallida');
        navigationService.showWarning('Por favor complete todos los campos requeridos');
        return;
      }
      
      if (userRole == 'professional' && workDays.value.isEmpty) {
        navigationService.showWarning('Debe seleccionar al menos un día de trabajo');
        return;
      }
      
      try {
        isLoading.value = true;
        errorMessage.value = null;
        
        if (user == null) {
          throw Exception('No hay usuario autenticado');
        }
        
        if (userRole == 'professional') {
          // Crear availability map
          final availability = {
            'workDays': workDays.value,
            'startTime': startTimeController.text.trim(),
            'endTime': endTimeController.text.trim(),
            'breakDuration': int.tryParse(breakDurationController.text.trim()) ?? 30,
          };

          // Crear professional model
          final professional = ProfessionalModel(
            id: user.uid,
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            email: user.email ?? '',
            phoneN: phoneController.text.trim(),
            dni: dniController.text.trim(),
            consultingAddress: addressController.text.trim(),
            licenseNumber: licenseController.text.trim(),
            speciality: selectedSpeciality.value,
            birthDate: dobController.text.isNotEmpty
                ? DateTime.parse(dobController.text)
                : null,
            availability: availability,
            status: 'active',
            profileCompleted: true,  // ✅ MARCAR COMO COMPLETADO
          );
          
          // Validar datos del profesional
          final validationError = professionalService.validateProfessionalData(professional);
          if (validationError != null) {
            throw Exception(validationError);
          }
          
          // Guardar usando el servicio
          await professionalService.updateProfessional(user.uid, professional.toMap());
          
          // Actualizar el provider
          await ref.read(professionalProvider.notifier).refresh();
        } else {
          // Crear patient model
          final patient = PatientModel(
            id: user.uid,
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            email: user.email ?? '',
            phoneN: phoneController.text.trim(),
            dni: dniController.text.trim(),
            birthDate: dobController.text.isNotEmpty
                ? DateTime.parse(dobController.text)
                : null,
            status: 'active',
            profileCompleted: true,  // ✅ MARCAR COMO COMPLETADO
          );
          
          // Validar datos del paciente
          final validationError = patientService.validatePatientData(patient);
          if (validationError != null) {
            throw Exception(validationError);
          }
          
          // Guardar usando el servicio
          await patientService.updatePatient(user.uid, patient.toMap());
          
          // Actualizar el provider
          await ref.read(patientProfileProvider.notifier).refresh();
        }
        
        // Recargar sesión
        await ref.read(sessionProvider.notifier).reloadSession();
        
        // Pequeña espera para asegurar actualización
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Mostrar mensaje de éxito
        navigationService.showSuccess('Perfil actualizado correctamente');
        
        // Navegar a home según rol
        if (userRole == 'professional') {
          navigationService.replaceTo(RoutePaths.professionalHome);
        } else {
          navigationService.replaceTo(RoutePaths.patientHome);
        }
      } catch (e, st) {
        ErrorLogger.logError('Error al actualizar el perfil', e, st);
        errorMessage.value = e.toString();
        navigationService.showError('Error al actualizar el perfil: ${e.toString()}');
      } finally {
        isLoading.value = false;
      }
    }

    // Navigation buttons
    Widget buildNavigationButtons() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (currentStep.value > 0)
            ElevatedButton.icon(
              onPressed: isLoading.value
                  ? null
                  : () {
                      currentStep.value--;
                    },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )
          else
            const SizedBox(width: 120),
          
          // Next/Save button
          ElevatedButton.icon(
            onPressed: isLoading.value
                ? null
                : () {
                    if (currentStep.value == steps.length - 1) {
                      saveProfile();
                    } else if (formKey.value.currentState!.validate()) {
                      currentStep.value++;
                    }
                  },
            icon: Icon(currentStep.value == steps.length - 1 ? Icons.save : Icons.arrow_forward),
            label: Text(currentStep.value == steps.length - 1 ? 'Guardar' : 'Siguiente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01303A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Completa tu Perfil'),
          backgroundColor: const Color(0xFF01303A),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: formKey.value,
                  child: Column(
                    children: [
                      // Progress indicator
                      Container(
                        color: const Color(0xFF01303A),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: LinearProgressIndicator(
                                value: (currentStep.value + 1) / steps.length,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    steps[currentStep.value],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
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
                            const SizedBox(height: 24),
                            
                            // Error message
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
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 16),
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
                            buildStepContent(),
                            
                            const SizedBox(height: 32),
                            
                            // Navigation buttons
                            buildNavigationButtons(),
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
  
  Widget _buildDayChip(
    ValueNotifier<List<String>> workDays,
    String day,
    String displayName,
  ) {
    final isSelected = workDays.value.contains(day);
    
    return FilterChip(
      label: Text(displayName),
      selected: isSelected,
      selectedColor: const Color(0xFF01303A).withOpacity(0.15),
      checkmarkColor: const Color(0xFF01303A),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF01303A) : Colors.grey[300]!,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF01303A) : Colors.black87,
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