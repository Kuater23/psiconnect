import 'package:flutter/material.dart';
import 'package:Psiconnect/src/providers/professional_provider.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/helpers/time_format_helper.dart';

class ProfessionalHome extends ConsumerWidget {
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
      body: professionalState.isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  professionalState.hasData && !professionalState.isEditing
                      ? _buildProfessionalInfo(ref)
                      : _buildForm(ref, context),
                ],
              ),
            ),
    );
  }

  Widget _buildForm(WidgetRef ref, BuildContext context) {
    final professionalState = ref.watch(professionalProvider);
    final professionalNotifier = ref.read(professionalProvider.notifier);

    // Form keys y controladores para manejar los campos de formulario
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: professionalState.name);
    final _lastNameController =
        TextEditingController(text: professionalState.lastName);
    final _addressController =
        TextEditingController(text: professionalState.address);
    final _phoneController =
        TextEditingController(text: professionalState.phone);
    final _documentNumberController =
        TextEditingController(text: professionalState.documentNumber);
    final _licenseNumberController =
        TextEditingController(text: professionalState.licenseNumber);
    final List<String> _selectedDays = professionalState.selectedDays.toList();
    TimeOfDay? _startTime = professionalState.startTime != null
        ? TimeFormatHelper.parseTime(professionalState.startTime!)
        : null;
    TimeOfDay? _endTime = professionalState.endTime != null
        ? TimeFormatHelper.parseTime(professionalState.endTime!)
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
          _buildDaysSelector(ref, _selectedDays),
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
              if (_formKey.currentState!.validate()) {
                // Guardar los datos actualizados
                professionalNotifier.saveUserData(
                  name: _nameController.text,
                  lastName: _lastNameController.text,
                  address: _addressController.text,
                  phone: _phoneController.text,
                  documentNumber: _documentNumberController.text,
                  licenseNumber: _licenseNumberController.text,
                  selectedDays: _selectedDays,
                  startTime: _startTime != null
                      ? TimeFormatHelper.formatTimeIn24Hours(_startTime!)
                      : '09:00',
                  endTime: _endTime != null
                      ? TimeFormatHelper.formatTimeIn24Hours(_endTime!)
                      : '17:00',
                );
                professionalNotifier
                    .setEditing(false); // Salir del modo edición
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días Disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          children: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
              .map((day) => CheckboxListTile(
                    title: Text(day),
                    value: selectedDays.contains(day),
                    onChanged: (isSelected) {
                      if (isSelected ?? false) {
                        selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    },
                  ))
              .toList(),
        ),
        SizedBox(height: 10),
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

  Widget _buildProfessionalInfo(WidgetRef ref) {
    final professionalState = ref.watch(professionalProvider);
    final professionalNotifier = ref.read(professionalProvider.notifier);

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
              'Dr. ${professionalState.name} ${professionalState.lastName}',
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
                Icons.location_on, 'Consultorio: ${professionalState.address}'),
            _buildInfoRow(Icons.phone, 'Teléfono: ${professionalState.phone}'),
            _buildInfoRow(Icons.badge,
                'Número de Documento: ${professionalState.documentNumber}'),
            _buildInfoRow(Icons.account_balance,
                'Número de Matrícula: ${professionalState.licenseNumber}'),
            _buildInfoRow(
              Icons.calendar_today,
              'Disponibilidad: ${professionalState.selectedDays.join(', ')} de ${professionalState.startTime ?? '09:00'} a ${professionalState.endTime ?? '17:00'}',
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  professionalNotifier.setEditing(true);
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
