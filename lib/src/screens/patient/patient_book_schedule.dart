import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorAvailability {
  final List<String> workDays;
  final String startTime;
  final String endTime;
  final int breakDuration;

  DoctorAvailability({
    required this.workDays,
    required this.startTime,
    required this.endTime,
    required this.breakDuration,
  });

  factory DoctorAvailability.fromMap(Map<String, dynamic> data) {
    final List<String> fullDays = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom'
    ];
    
    return DoctorAvailability(
      workDays: List<String>.from(data['workDays'] ?? fullDays),
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
      breakDuration: data['breakDuration'] ?? 15,
    );
  }
}

class PatientBookSchedule extends StatefulWidget {
  final VoidCallback toggleTheme;

  const PatientBookSchedule({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _PatientBookScheduleState createState() => _PatientBookScheduleState();
}

class _PatientBookScheduleState extends State<PatientBookSchedule> {
  String? selectedDayOfWeek;
  DateTime? selectedDate;
  List<TimeOfDay> availableTimes = [];
  TimeOfDay? selectedTime;
  bool isLoadingTimes = false;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Agendar Cita'),
        ),
        body: const Center(
          child: Text('No se proporcionaron datos del profesional.'),
        ),
      );
    }
    
    final String lastName = args['lastName'];
    final String name = args['firstName'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Agenda de Dr. $lastName, $name'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color.fromRGBO(2, 60, 67, 1),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('doctors')
            .where('lastName', isEqualTo: lastName)
            .where('firstName', isEqualTo: name)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Error al obtener los datos del profesional.'));
          }

          final professionalData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final availability = DoctorAvailability.fromMap(professionalData);
          final professionalId = snapshot.data!.docs.first.id;

          return _buildSchedulingForm(context, professionalData, availability, professionalId);
        },
      ),
    );
  }

  Widget _buildSchedulingForm(
    BuildContext context,
    Map<String, dynamic> professionalData,
    DoctorAvailability availability,
    String professionalId,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Theme.of(context).cardColor,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfessionalHeader(professionalData),
              const Divider(color: Colors.blueAccent),
              _buildProfessionalInfo(professionalData),
              const SizedBox(height: 16),
              _buildAvailabilitySection(availability, professionalId),
              const SizedBox(height: 16),
              _buildActionButtons(professionalId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader(Map<String, dynamic> professionalData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.person, color: Colors.blueAccent, size: 40),
            SizedBox(width: 10),
          ],
        ),
        Text(
          'Dr. ${professionalData['lastName']}, ${professionalData['firstName']}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalInfo(Map<String, dynamic> professionalData) {
    return Column(
      children: [
        _buildInfoRow(Icons.location_on, 'Dirección: ${professionalData['address']}'),
        _buildInfoRow(Icons.phone, 'Teléfono: ${professionalData['phoneN']}'),
        if (professionalData.containsKey('specialty'))
          _buildInfoRow(Icons.school, 'Especialidad: ${professionalData['specialty']}'),
      ],
    );
  }

  Widget _buildAvailabilitySection(DoctorAvailability availability, String professionalId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disponibilidad:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        _buildDaySelector(availability),
        if (selectedDayOfWeek != null) ...[
          const SizedBox(height: 16),
          _buildDateSelector(availability),
        ],
        if (selectedDate != null && !isLoadingTimes) ...[
          const SizedBox(height: 16),
          _buildTimeSelector(),
        ],
        if (isLoadingTimes)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildDaySelector(DoctorAvailability availability) {
    return DropdownButtonFormField<String>(
      decoration: _getInputDecoration('Selecciona un día'),
      value: selectedDayOfWeek,
      onChanged: (String? newValue) {
        setState(() {
          selectedDayOfWeek = newValue;
          selectedDate = null;
          availableTimes = [];
          selectedTime = null;
        });
      },
      items: availability.workDays.map<DropdownMenuItem<String>>((day) {
        return DropdownMenuItem<String>(
          value: day,
          child: Text(
            day,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector(DoctorAvailability availability) {
    return DropdownButtonFormField<DateTime>(
      decoration: _getInputDecoration('Selecciona una fecha'),
      value: selectedDate,
      onChanged: (DateTime? newValue) async {
        if (newValue != null) {
          setState(() {
            selectedDate = newValue;
            isLoadingTimes = true;
          });
          try {
            final times = await _getAvailableTimes(availability, newValue);
            setState(() {
              availableTimes = times;
              selectedTime = null;
              isLoadingTimes = false;
            });
          } catch (e) {
            setState(() {
              isLoadingTimes = false;
            });
            debugPrint('Error al cargar los horarios: $e');
          }
        }
      },
      items: _getAvailableDates(selectedDayOfWeek!, DateTime.now().year, DateTime.now().month)
          .map<DropdownMenuItem<DateTime>>((date) {
        return DropdownMenuItem<DateTime>(
          value: date,
          child: Text(
            '${_dayOfWeekToString(date.weekday)} ${date.day} de ${_monthToString(date.month)} ${date.year}',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horarios disponibles:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TimeOfDay>(
          decoration: _getInputDecoration('Selecciona una hora'),
          value: selectedTime,
          onChanged: (TimeOfDay? newValue) {
            setState(() {
              selectedTime = newValue;
            });
          },
          items: availableTimes.map<DropdownMenuItem<TimeOfDay>>((time) {
            return DropdownMenuItem<TimeOfDay>(
              value: time,
              child: Text(
                time.format(context),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String professionalId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: selectedDate != null && selectedTime != null
                ? () => _bookAppointment(professionalId)
                : null,
            icon: const Icon(Icons.check, color: Colors.blueAccent),
            label: const Text(
              'Reservar sesión',
              style: TextStyle(color: Colors.blueAccent),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blueAccent),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearSelection,
            icon: const Icon(Icons.clear, color: Colors.redAccent),
            label: const Text(
              'Limpiar',
              style: TextStyle(color: Colors.redAccent),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        ),
      ),
      filled: true,
      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
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

  Future<List<TimeOfDay>> _getAvailableTimes(
    DoctorAvailability availability,
    DateTime selectedDate,
  ) async {
    final List<TimeOfDay> times = [];
    final startTime = _parseTime(availability.startTime);
    final endTime = _parseTime(availability.endTime);

    final reservationsSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('date', isEqualTo: selectedDate.toIso8601String())
        .where('status', isEqualTo: 'RESERVADO')
        .get();

    final reservedTimes = reservationsSnapshot.docs
        .map((doc) => _parseTime(doc.data()['time'] as String))
        .toList();

    TimeOfDay currentTime = startTime;
    while (_compareTime(currentTime, endTime) < 0) {
      if (!reservedTimes.any((reserved) => 
          reserved.hour == currentTime.hour && 
          reserved.minute == currentTime.minute)) {
        times.add(currentTime);
      }
      currentTime = _addMinutes(currentTime, 60 + availability.breakDuration);
    }

    return times;
  }

  int _compareTime(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour != time2.hour) return time1.hour - time2.hour;
    return time1.minute - time2.minute;
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
    );
  }

    Future<void> _bookAppointment(String professionalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final appointmentDay =
        '${_dayOfWeekToString(selectedDate!.weekday)} ${selectedDate!.day} de ${_monthToString(selectedDate!.month)} ${selectedDate!.year} a las ${selectedTime!.format(context)}';

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'appointmentDay': appointmentDay,
        'date': selectedDate!.toIso8601String(),
        'time': '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
        'patientId': user.uid,
        'professionalId': professionalId,
        'status': 'RESERVADO',
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión reservada para $appointmentDay'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear selection
      _clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reservar la cita: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSelection() {
    setState(() {
      selectedDayOfWeek = null;
      selectedDate = null;
      selectedTime = null;
      availableTimes = [];
    });
  }

  List<DateTime> _getAvailableDates(String dayOfWeek, int year, int month) {
    List<DateTime> dates = [];
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
    DateTime today = DateTime.now();

    for (DateTime date = firstDayOfMonth;
        date.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      if (date.weekday == _dayOfWeekToInt(dayOfWeek) && 
          date.isAfter(today.subtract(const Duration(days: 1)))) {
        dates.add(date);
      }
    }

    return dates;
  }

  int _dayOfWeekToInt(String dayOfWeek) {
  switch (dayOfWeek.toLowerCase().substring(0, 3)) {
    case 'lun':
      return DateTime.monday;
    case 'mar':
      return DateTime.tuesday;
    case 'mié':
    case 'mie':
      return DateTime.wednesday;
    case 'jue':
      return DateTime.thursday;
    case 'vie':
      return DateTime.friday;
    case 'sáb':
    case 'sab':
      return DateTime.saturday;
    case 'dom':
      return DateTime.sunday;
    default:
      throw ArgumentError('Día de la semana inválido: $dayOfWeek');
  }
}

  String _dayOfWeekToString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miércoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        throw ArgumentError('Día de la semana inválido: $weekday');
    }
  }

  String _monthToString(int month) {
    switch (month) {
      case 1:
        return 'enero';
      case 2:
        return 'febrero';
      case 3:
        return 'marzo';
      case 4:
        return 'abril';
      case 5:
        return 'mayo';
      case 6:
        return 'junio';
      case 7:
        return 'julio';
      case 8:
        return 'agosto';
      case 9:
        return 'septiembre';
      case 10:
        return 'octubre';
      case 11:
        return 'noviembre';
      case 12:
        return 'diciembre';
      default:
        throw ArgumentError('Mes inválido: $month');
    }
  }
}