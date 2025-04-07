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
      builder: (dialogContext) => AlertDialog(
        title: Text('Editar Información'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Dirección del consultorio'),
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _documentNumberController,
                decoration: InputDecoration(labelText: 'DNI'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _licenseNumberController,
                decoration: InputDecoration(labelText: 'Número de matrícula'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
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
                  SnackBar(content: Text('Cambios guardados correctamente')),
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
          ),
        ],
      ),
    );
  }
}
