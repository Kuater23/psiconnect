import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/helpers/time_format_helper.dart';

class DoctorFields {
  static const String dob = 'dob';
  static const String email = 'email';
  static const String address= 'address';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String password = 'password';
  static const String phoneN = 'phoneN';
  static const String dni = 'dni';
  static const String uid = 'uid';
  static const String license = 'license';
  static const String specialty = 'specialty';
  static const String breakDuration = 'breakDuration';
  static const String startTime = 'startTime';
  static const String endTime = 'endTime';
  static const String workDays = 'workDays';
}

class ProfessionalHome extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  const ProfessionalHome({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _ProfessionalHomeState createState() => _ProfessionalHomeState();
}

class _ProfessionalHomeState extends ConsumerState<ProfessionalHome> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _hasData = false;
  List<String> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedSpecialty;

  final List<String> _specialties = [
    'Psicología Clínica',
    'Psicología Educativa',
    'Psicología Organizacional',
    'Psicología Social',
    'Psicología Forense',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadDoctorData();
  }

  void _initializeControllers() {
    _controllers = {
      DoctorFields.firstName: TextEditingController(),
      DoctorFields.lastName: TextEditingController(),
      DoctorFields.dob: TextEditingController(),
      DoctorFields.phoneN: TextEditingController(),
      DoctorFields.address: TextEditingController(),
      DoctorFields.dni: TextEditingController(),
      DoctorFields.email: TextEditingController(),
      DoctorFields.license: TextEditingController(),
      DoctorFields.specialty: TextEditingController(),
      DoctorFields.breakDuration: TextEditingController(text: '15'),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDoctorData() async {
    try {
      setState(() => _isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('Firebase Data: $data');
        
        setState(() {
          _controllers[DoctorFields.firstName]?.text = data[DoctorFields.firstName] ?? '';
          _controllers[DoctorFields.lastName]?.text = data[DoctorFields.lastName] ?? '';
          _controllers[DoctorFields.dob]?.text = data[DoctorFields.dob] ?? '';
          _controllers[DoctorFields.phoneN]?.text = data[DoctorFields.phoneN] ?? '';
          _controllers[DoctorFields.address]?.text = data[DoctorFields.address] ?? '';
          _controllers[DoctorFields.dni]?.text = data[DoctorFields.dni] ?? '';
          _controllers[DoctorFields.email]?.text = data[DoctorFields.email] ?? '';
          _controllers[DoctorFields.license]?.text = data[DoctorFields.license] ?? '';
          _controllers[DoctorFields.specialty]?.text = data[DoctorFields.specialty] ?? '';
          _controllers[DoctorFields.breakDuration]?.text = 
              (data[DoctorFields.breakDuration] ?? '15').toString();
          
          if (data[DoctorFields.startTime] != null) {
            _startTime = TimeFormatHelper.parseTime(data[DoctorFields.startTime]);
          }
          if (data[DoctorFields.endTime] != null) {
            _endTime = TimeFormatHelper.parseTime(data[DoctorFields.endTime]);
          }
          
          _selectedDays = List<String>.from(data[DoctorFields.workDays] ?? []);
          _selectedSpecialty = data[DoctorFields.specialty];
          
          _hasData = _validateMandatoryData(data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error loading data: ${e.toString()}');
    }
  }

  bool _validateMandatoryData(Map<String, dynamic> data) {
    final requiredFields = [
      DoctorFields.firstName,
      DoctorFields.lastName,
      DoctorFields.dob,
      DoctorFields.phoneN,
      DoctorFields.address,
      DoctorFields.dni,
      DoctorFields.email,
      DoctorFields.license,
      DoctorFields.specialty,
    ];
    return requiredFields.every((field) => 
      data[field]?.toString().isNotEmpty ?? false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

    Widget _buildDoctorInfo() {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(thickness: 1),
            _buildInfoDetails(),
            const SizedBox(height: 20),
            _buildEditButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.person, color: Colors.blue, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Dr. ${_controllers[DoctorFields.firstName]!.text} ${_controllers[DoctorFields.lastName]!.text}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDetails() {
    final infoItems = {
      Icons.calendar_today: 'Fecha de nacimiento: ${_controllers[DoctorFields.dob]!.text}',
      Icons.phone: 'Teléfono: ${_controllers[DoctorFields.phoneN]!.text}',
      Icons.location_on: 'Direccion: ${_controllers[DoctorFields.address]!.text}',
      Icons.badge: 'DNI: ${_controllers[DoctorFields.dni]!.text}',
      Icons.email: 'Email: ${_controllers[DoctorFields.email]!.text}',
      Icons.medical_services: 'Licencia: ${_controllers[DoctorFields.license]!.text}',
      Icons.psychology: 'Especialidad: $_selectedSpecialty',
      Icons.schedule: 'Horario: ${_startTime != null ? TimeFormatHelper.formatTimeIn24Hours(_startTime!) : "--"} - ${_endTime != null ? TimeFormatHelper.formatTimeIn24Hours(_endTime!) : "--"}',
      Icons.timer: 'Descanso: ${_controllers[DoctorFields.breakDuration]!.text} min',
      Icons.calendar_view_day: 'Días: ${_selectedDays.join(", ")}',
    };

    return Column(
      children: infoItems.entries
          .map((entry) => _buildInfoRow(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _isEditing = true),
        icon: const Icon(Icons.edit, color: Colors.blue),
        label: const Text('Editar', style: TextStyle(color: Colors.blue)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ..._buildFormFields(),
          const SizedBox(height: 20),
          _buildSpecialtyDropdown(),
          const SizedBox(height: 30),
          _buildScheduleSection(),
          const SizedBox(height: 20),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSpecialtyDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Especialidad',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      value: _selectedSpecialty ?? _specialties.first,
      items: _specialties.map((String specialty) {
        return DropdownMenuItem<String>(
          value: specialty,
          child: Text(specialty),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSpecialty = newValue;
        });
      },
      validator: (value) => value == null ? 'Seleccione una especialidad' : null,
    );
  }

  List<Widget> _buildFormFields() {
  final fieldConfigs = {
    DoctorFields.firstName: Tuple3('Nombre', TextInputType.text, true),
    DoctorFields.lastName: Tuple3('Apellido', TextInputType.text, true),
    DoctorFields.dob: Tuple3('Fecha de Nacimiento', TextInputType.datetime, true),
    DoctorFields.phoneN: Tuple3('Teléfono', TextInputType.phone, false),
    DoctorFields.address: Tuple3('Direccion', TextInputType.text, false),
    DoctorFields.dni: Tuple3('DNI', TextInputType.text, true),
    DoctorFields.email: Tuple3('Email', TextInputType.emailAddress, false),
    DoctorFields.license: Tuple3('Número de Licencia', TextInputType.text, true),
  };

  return fieldConfigs.entries.map((entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildTextField(
        labelText: entry.value.item1,
        controller: _controllers[entry.key]!,
        keyboardType: entry.value.item2,
        validator: _getValidator(entry.key),
        readOnly: entry.value.item3,
      ),
    );
  }).toList();
}

  Widget _buildTextField({
  required String labelText,
  required TextEditingController controller,
  required TextInputType keyboardType,
  required String? Function(String?) validator,
  required bool readOnly,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: readOnly,
      fillColor: readOnly ? Colors.black : null,
    ),
    keyboardType: keyboardType,
    validator: validator,
    readOnly: readOnly,
    enabled: !readOnly,
  );
}

  String? Function(String?) _getValidator(String field) {
    return (value) {
      if (value?.isEmpty ?? true) return 'Este campo es obligatorio';
      if (field == DoctorFields.email) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value!)) return 'Email inválido';
      }
      if (field == DoctorFields.phoneN) {
        final phoneRegex = RegExp(r'^\d{9,}$');
        if (!phoneRegex.hasMatch(value!)) return 'Teléfono inválido';
      }
      return null;
    };
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horario de Atención',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        _buildWorkDaysSelector(),
        const SizedBox(height: 15),
        _buildWorkHoursSelector(),
        const SizedBox(height: 15),
        _buildBreakDurationField(),
      ],
    );
  }

  Widget _buildWorkDaysSelector() {
    final daysOfWeek = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return Wrap(
      spacing: 8.0,
      children: daysOfWeek.map((day) {
        final isSelected = _selectedDays.contains(day);
        return ChoiceChip(
          label: Text(day),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildWorkHoursSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTimePickerField(
            'Hora inicio',
            _startTime,
            (time) => setState(() => _startTime = time),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildTimePickerField(
            'Hora fin',
            _endTime,
            (time) => setState(() => _endTime = time),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerField(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      controller: TextEditingController(
        text: time != null ? TimeFormatHelper.formatTimeIn24Hours(time) : '',
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
    );
  }

  Widget _buildBreakDurationField() {
    return TextFormField(
      controller: _controllers[DoctorFields.breakDuration],
      decoration: InputDecoration(
        labelText: 'Duración del descanso (minutos)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo requerido';
        final duration = int.tryParse(value);
        if (duration == null || duration < 0) return 'Duración inválida';
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _saveDoctorData,
        icon: const Icon(Icons.save, color: Colors.blue),
        label: Text(
          _isEditing ? 'Actualizar' : 'Guardar',
          style: const TextStyle(color: Colors.blue),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _saveDoctorData() async {
  if (!_formKey.currentState!.validate()) return;
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final userData = {
      DoctorFields.phoneN: _controllers[DoctorFields.phoneN]!.text.trim(),
      DoctorFields.address: _controllers[DoctorFields.address]!.text.trim(),
      DoctorFields.email: _controllers[DoctorFields.email]!.text.trim(),
      DoctorFields.specialty: _selectedSpecialty,
      DoctorFields.breakDuration: int.tryParse(_controllers[DoctorFields.breakDuration]!.text.trim()) ?? 15,
      DoctorFields.startTime: _startTime != null ? TimeFormatHelper.formatTimeIn24Hours(_startTime!) : null,
      DoctorFields.endTime: _endTime != null ? TimeFormatHelper.formatTimeIn24Hours(_endTime!) : null,
      DoctorFields.workDays: _selectedDays,
    };

    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(user.uid)
        .update(userData);

    setState(() {
      _hasData = true;
      _isEditing = false;
    });
    _showSnackBar('Datos actualizados correctamente');
  } catch (e) {
    _showSnackBar('Error: ${e.toString()}');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _hasData
              ? 'Dr. ${_controllers[DoctorFields.firstName]!.text}'
              : 'Perfil Profesional',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(toggleTheme: widget.toggleTheme),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: (!_hasData || _isEditing) 
                  ? _buildForm() 
                  : _buildDoctorInfo(),
            ),
    );
  }
}

class Tuple3<T1, T2, T3> {
  final T1 item1;
  final T2 item2;
  final T3 item3;
  const Tuple3(this.item1, this.item2, this.item3);
}