import 'package:Psiconnect/features/professional/models/professional_model.dart';
import 'package:flutter/material.dart';
import 'package:Psiconnect/features/professional/providers/professional_providers.dart';
import 'package:Psiconnect/navigation/shared_drawer.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:Psiconnect/core/utils/time_format_helper.dart';

class ProfessionalHome extends HookConsumerWidget {
  final VoidCallback toggleTheme;

  ProfessionalHome({required this.toggleTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professionalState = ref.watch(professionalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Profesional'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(),
      body: professionalState.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(professionalProvider.notifier).refresh(),
                child: Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (professional) {
          if (professional == null) {
            return _buildEmptyState(context, ref);
          }
          
          return professional.profileCompleted
              ? _buildProfessionalInfo(professional, ref, context)
              : _buildForm(professional, ref, context);
        },
      ),
    );
  }

  Widget _buildForm(ProfessionalModel professional, WidgetRef ref, BuildContext context) {
    final professionalNotifier = ref.read(professionalProvider.notifier);

    // Form keys and controllers for form fields
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: professional.firstName);
    final _lastNameController = TextEditingController(text: professional.lastName);
    final _addressController = TextEditingController(text: professional.address);
    final _phoneController = TextEditingController(text: professional.phoneN);
    final _documentNumberController = TextEditingController(text: professional.dni);
    final _licenseNumberController = TextEditingController(text: professional.license);
    
    // Use useState for selected days to ensure reactivity
    final selectedDays = useState<List<String>>(
      professional.workDays.isNotEmpty 
        ? List<String>.from(professional.workDays)
        : []
    );
    
    TimeOfDay? _startTime = professional.startTime.isNotEmpty
        ? TimeFormatHelper.parseTime(professional.startTime)
        : null;
    TimeOfDay? _endTime = professional.endTime.isNotEmpty
        ? TimeFormatHelper.parseTime(professional.endTime)
        : null;

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
            labelText: 'Dirección del consultorio',
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
          _buildDaysSelector(ref, selectedDays.value),
          _buildTimeSelector(
            context: context, // Pasa el contexto aquí
            label: 'Hora de Inicio',
            initialTime: _startTime ?? TimeOfDay(hour: 9, minute: 0),
            onTimePicked: (pickedTime) {
              _startTime = pickedTime;
            },
          ),
          _buildTimeSelector(
            context: context, // Pasa el contexto aquí
            label: 'Hora de Fin',
            initialTime: _endTime ?? TimeOfDay(hour: 17, minute: 0),
            onTimePicked: (pickedTime) {
              _endTime = pickedTime;
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && selectedDays.value.isNotEmpty) {
                // Save the updated data
                professionalNotifier.saveUserData(
                  firstName: _nameController.text,
                  lastName: _lastNameController.text,
                  address: _addressController.text,
                  phoneN: _phoneController.text,
                  dni: _documentNumberController.text,
                  license: _licenseNumberController.text,
                  workDays: selectedDays.value,
                  startTime: _startTime != null
                      ? TimeFormatHelper.formatTimeIn24Hours(_startTime!)
                      : '09:00',
                  endTime: _endTime != null
                      ? TimeFormatHelper.formatTimeIn24Hours(_endTime!)
                      : '17:00',
                );
                professionalNotifier.refresh(); // Refresh data after save
              } else if (selectedDays.value.isEmpty) {
                // Show an error snackbar for empty days
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Debe seleccionar al menos un día de atención'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Guardar'),
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
      decoration: InputDecoration(labelText: labelText),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDaysSelector(WidgetRef ref, List<String> selectedDays) {
    // State to trigger rebuilds when selections change
    final updateCounter = useState(0);
    
    // Define mapping between UI display (Spanish) and storage format (English)
    final dayMapping = {
      'Lunes': 'Monday',
      'Martes': 'Tuesday',
      'Miércoles': 'Wednesday',
      'Jueves': 'Thursday',
      'Viernes': 'Friday',
      'Sábado': 'Saturday',
      'Domingo': 'Sunday',
    };
    
    // For debugging - print the current selected days 
    print('Current selected days in _buildDaysSelector: $selectedDays');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días Disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          children: dayMapping.entries.map((entry) {
            final spanishDay = entry.key;
            final englishDay = entry.value;
            
            // Check if the English day name exists in the selected days
            final isSelected = selectedDays.contains(englishDay);
            
            return CheckboxListTile(
              title: Text(spanishDay),
              value: isSelected,
              onChanged: (isSelected) {
                if (isSelected ?? false) {
                  if (!selectedDays.contains(englishDay)) {
                    selectedDays.add(englishDay);
                  }
                } else {
                  selectedDays.remove(englishDay);
                }
                // Force UI refresh
                updateCounter.value++;
                print('Updated selected days: $selectedDays'); // Debug log
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        if (selectedDays.isEmpty)
          Text(
            'Debe seleccionar al menos un día',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required BuildContext context,
    required String label,
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimePicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          title: Text(
            TimeFormatHelper.formatTimeIn24Hours(initialTime),
          ),
          trailing: Icon(Icons.access_time),
          onTap: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onTimePicked(picked);
            }
          },
        )
      ],
    );
  }

  Widget _buildProfessionalInfo(ProfessionalModel professional, WidgetRef ref, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. ${professional.fullName}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Especialista en ${professional.speciality}',
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
              Divider(),
              _buildInfoRow(Icons.location_on, 'Consultorio: ${professional.address}'),
              _buildInfoRow(Icons.phone, 'Teléfono: ${professional.phoneN}'),
              _buildInfoRow(Icons.badge, 'Número de Documento: ${professional.dni}'),
              _buildInfoRow(Icons.account_balance, 'Número de Matrícula: ${professional.license}'),
              _buildInfoRow(
                Icons.calendar_today,
                'Disponibilidad: ${_formatDaysInSpanish(professional.workDays)} de ${professional.startTime} a ${professional.endTime}',
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showEditDialog(context, professional, ref),
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
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.contains('Disponibilidad:') && !text.contains('No disponible')) {
      // Extract the days list from the text and convert to Spanish before displaying
      final parts = text.split(':');
      if (parts.length > 1) {
        final daysPart = parts[1].trim();
        final dayTimeParts = daysPart.split(' de ');
        if (dayTimeParts.length > 0) {
          final daysList = dayTimeParts[0].split(', ');
          
          // Map English day names to Spanish
          final translatedDays = daysList.map((day) {
            switch (day) {
              case 'Monday': return 'Lunes';
              case 'Tuesday': return 'Martes';
              case 'Wednesday': return 'Miércoles';
              case 'Thursday': return 'Jueves';
              case 'Friday': return 'Viernes';
              case 'Saturday': return 'Sábado';
              case 'Sunday': return 'Domingo';
              default: return day;
            }
          }).join(', ');
          
          // Recreate the text with translated days
          text = 'Disponibilidad: $translatedDays de ${dayTimeParts.length > 1 ? dayTimeParts[1] : ""}';
        }
      }
    }
    
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

  // Add this helper method to convert English day names to Spanish
  String _formatDaysInSpanish(List<String> days) {
    if (days.isEmpty) return 'No disponible';
    
    // Map English day names to Spanish
    final dayMapping = {
      'Monday': 'Lunes',
      'Tuesday': 'Martes',
      'Wednesday': 'Miércoles',
      'Thursday': 'Jueves',
      'Friday': 'Viernes',
      'Saturday': 'Sábado',
      'Sunday': 'Domingo',
    };
    
    // Convert each day to its Spanish equivalent
    final spanishDays = days.map((day) => dayMapping[day] ?? day).toList();
    return spanishDays.join(', ');
  }

  // Add this method to your ProfessionalHome class
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No se encontró información profesional',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Es posible que necesites completar tu perfil',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(professionalProvider.notifier).refresh(),
            child: Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to your ProfessionalHome class
  void _showEditDialog(BuildContext context, ProfessionalModel professional, WidgetRef ref) {
    final _nameController = TextEditingController(text: professional.firstName);
    final _lastNameController = TextEditingController(text: professional.lastName);
    final _addressController = TextEditingController(text: professional.address);
    final _phoneController = TextEditingController(text: professional.phoneN);
    final _documentNumberController = TextEditingController(text: professional.dni);
    final _licenseNumberController = TextEditingController(text: professional.license);
    
    // Create a copy of work days that we can modify
    final selectedDays = [...professional.workDays];
    
    // Parse times if they exist
    TimeOfDay startTime = professional.startTime.isNotEmpty
        ? TimeFormatHelper.parseTime(professional.startTime) ?? TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(hour: 9, minute: 0);
        
    TimeOfDay endTime = professional.endTime.isNotEmpty
        ? TimeFormatHelper.parseTime(professional.endTime) ?? TimeOfDay(hour: 17, minute: 0)
        : TimeOfDay(hour: 17, minute: 0);
    
    // Show the edit dialog
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(maxWidth: 500), // Limitar el ancho máximo
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
                    'Editar Información',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información personal - Section header
                      Text(
                        'Información Personal',
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
                              context: context,
                              controller: _nameController,
                              label: 'Nombre',
                              icon: Icons.person_outline,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildEditField(
                              context: context,
                              controller: _lastNameController,
                              label: 'Apellido',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // DNI y teléfono en la misma fila
                      Row(
                        children: [
                          Expanded(
                            child: _buildEditField(
                              context: context,
                              controller: _documentNumberController,
                              label: 'DNI',
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildEditField(
                              context: context,
                              controller: _phoneController,
                              label: 'Teléfono',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Información profesional - Section header
                      Text(
                        'Información Profesional',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      _buildEditField(
                        context: context,
                        controller: _addressController,
                        label: 'Dirección del Consultorio',
                        icon: Icons.location_on_outlined,
                      ),
                      SizedBox(height: 16),
                      
                      _buildEditField(
                        context: context,
                        controller: _licenseNumberController,
                        label: 'Número de Matrícula',
                        icon: Icons.card_membership_outlined,
                      ),
                      SizedBox(height: 24),
                      
                      // Días de trabajo - Section header
                      Text(
                        'Días de Trabajo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Selección de días con chips interactivos
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDayChip(dialogContext, selectedDays, 'Monday', 'Lunes'),
                          _buildDayChip(dialogContext, selectedDays, 'Tuesday', 'Martes'),
                          _buildDayChip(dialogContext, selectedDays, 'Wednesday', 'Miércoles'),
                          _buildDayChip(dialogContext, selectedDays, 'Thursday', 'Jueves'),
                          _buildDayChip(dialogContext, selectedDays, 'Friday', 'Viernes'),
                          _buildDayChip(dialogContext, selectedDays, 'Saturday', 'Sábado'),
                          _buildDayChip(dialogContext, selectedDays, 'Sunday', 'Domingo'),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Horarios de trabajo - Section header
                      Text(
                        'Horarios de Atención',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Horarios en la misma fila
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeSelectorDialog(
                              context: dialogContext,
                              label: 'Hora de inicio',
                              initialTime: startTime,
                              onTimeSelected: (time) {
                                startTime = time;
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildTimeSelectorDialog(
                              context: dialogContext,
                              label: 'Hora de fin',
                              initialTime: endTime,
                              onTimeSelected: (time) {
                                endTime = time;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('Cancelar'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Verificar si hay al menos un día seleccionado
                          if (selectedDays.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Debe seleccionar al menos un día de trabajo'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          // Save changes
                          await ref.read(professionalProvider.notifier).saveUserData(
                            firstName: _nameController.text.trim(),
                            lastName: _lastNameController.text.trim(),
                            address: _addressController.text.trim(),
                            phoneN: _phoneController.text.trim(),
                            dni: _documentNumberController.text.trim(),
                            license: _licenseNumberController.text.trim(),
                            workDays: selectedDays,
                            startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                            endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                          );
                          
                          // Close the dialog
                          Navigator.pop(dialogContext);
                          
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cambios guardados correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al guardar los cambios: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
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
      ),
    );
  }

  // Widget helper para construir campos de edición consistentes
  Widget _buildEditField({
    required BuildContext context,
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
    );
  }

  // Widget para seleccionar horarios con mejor UI
  Widget _buildTimeSelectorDialog({
    required BuildContext context,
    required String label,
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
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
              Icons.access_time,
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
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${initialTime.hour.toString().padLeft(2, '0')}:${initialTime.minute.toString().padLeft(2, '0')}',
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
    );
  }

  // Widget para chips de selección de días
  Widget _buildDayChip(
    BuildContext context,
    List<String> selectedDays,
    String dayValue,
    String displayText,
  ) {
    final isSelected = selectedDays.contains(dayValue);
    
    return StatefulBuilder(
      builder: (context, setState) => FilterChip(
        label: Text(displayText),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            if (!selectedDays.contains(dayValue)) {
              selectedDays.add(dayValue);
            }
          } else {
            selectedDays.remove(dayValue);
          }
          setState(() {}); // Actualizar UI del chip
        },
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }
}
