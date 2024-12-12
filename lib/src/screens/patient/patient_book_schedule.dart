import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientBookSchedule extends StatefulWidget {
  final VoidCallback toggleTheme;

  PatientBookSchedule({required this.toggleTheme});

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
          title: Text('Agendar Cita'),
        ),
        body: Center(
          child: Text('No se proporcionaron datos del profesional.'),
        ),
      );
    }
    final String lastName = args['lastName'];
    final String name = args['name'];

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Fondo según el tema
      appBar: AppBar(
        title: Text('Agenda de Dr. $lastName, $name'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Color.fromRGBO(
                2, 60, 67, 1), // Color base de Psiconnect para el fondo
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('lastName', isEqualTo: lastName)
            .where('name', isEqualTo: name)
            .where('role', isEqualTo: 'professional')
            .get()
            .then((snapshot) => snapshot.docs.first),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
                child: Text('Error al obtener los datos del profesional.'));
          }

          final professionalData =
              snapshot.data!.data() as Map<String, dynamic>;
          final availability =
              professionalData['availability'] as Map<String, dynamic>;
          final professionalId = snapshot.data!.id;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Theme.of(context).cardColor, // Color según el tema
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blueAccent, size: 40),
                        SizedBox(width: 10),
                        Text(
                          'Dr. $lastName, $name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: Colors.blueAccent), // Línea azul separadora
                    SizedBox(height: 10),
                    _buildInfoRow(Icons.location_on,
                        'Dirección: ${professionalData['address']}'),
                    _buildInfoRow(
                        Icons.phone, 'Teléfono: ${professionalData['phone']}'),
                    SizedBox(height: 16),
                    Text(
                      'Disponibilidad:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Selecciona un día',
                        labelStyle: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Colors.black),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Colors.black),
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .inputDecorationTheme
                            .fillColor, // Color según el tema
                      ),
                      dropdownColor:
                          Theme.of(context).cardColor, // Color según el tema
                      value: selectedDayOfWeek,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDayOfWeek = newValue;
                          selectedDate = null;
                          availableTimes = [];
                          selectedTime = null;
                        });
                      },
                      items: (availability['days'] as List<dynamic>)
                          .map<DropdownMenuItem<String>>((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day,
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black)),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    if (selectedDayOfWeek != null)
                      DropdownButtonFormField<DateTime>(
                        decoration: InputDecoration(
                          labelText: 'Selecciona una fecha',
                          labelStyle: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .inputDecorationTheme
                              .fillColor, // Color según el tema
                        ),
                        dropdownColor:
                            Theme.of(context).cardColor, // Color según el tema
                        value: selectedDate,
                        onChanged: (DateTime? newValue) async {
                          setState(() {
                            selectedDate = newValue;
                            isLoadingTimes = true;
                          });

                          try {
                            final times = await _getAvailableTimes(
                                professionalId, newValue!, availability);

                            setState(() {
                              availableTimes = times;
                              selectedTime = null;
                              isLoadingTimes = false;
                            });
                          } catch (e) {
                            setState(() {
                              isLoadingTimes = false;
                            });
                            // Manejar el error, mostrar un mensaje al usuario si es necesario
                            print('Error al cargar los horarios: $e');
                          }
                        },
                        items: _getAvailableDates(selectedDayOfWeek!,
                                DateTime.now().year, DateTime.now().month)
                            .map<DropdownMenuItem<DateTime>>((date) {
                          return DropdownMenuItem<DateTime>(
                            value: date,
                            child: Text(
                              '${_dayOfWeekToString(date.weekday)} ${date.day} de ${_monthToString(date.month)} ${date.year}',
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.black),
                            ),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: 16),
                    if (isLoadingTimes)
                      Center(child: CircularProgressIndicator())
                    else if (selectedDate != null) ...[
                      Text(
                        'Horarios disponibles:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<TimeOfDay>(
                        decoration: InputDecoration(
                          labelText: 'Selecciona una hora',
                          labelStyle: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.black),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .inputDecorationTheme
                              .fillColor, // Color según el tema
                        ),
                        dropdownColor:
                            Theme.of(context).cardColor, // Color según el tema
                        value: selectedTime,
                        onChanged: (TimeOfDay? newValue) {
                          setState(() {
                            selectedTime = newValue;
                          });
                        },
                        items: availableTimes
                            .map<DropdownMenuItem<TimeOfDay>>((time) {
                          return DropdownMenuItem<TimeOfDay>(
                            value: time,
                            child: Text(time.format(context),
                                style: TextStyle(
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color ??
                                        Colors.black)),
                          );
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: selectedDate != null &&
                                  selectedTime != null
                              ? () async {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    final patientId = user.uid;
                                    final appointmentDay =
                                        '${_dayOfWeekToString(selectedDate!.weekday)} ${selectedDate!.day} de ${_monthToString(selectedDate!.month)} ${selectedDate!.year} a las ${selectedTime!.format(context)}';
                                    final reservation = {
                                      'appointmentDay': appointmentDay,
                                      'date': selectedDate!.toIso8601String(),
                                      'time': selectedTime!.format(context),
                                      'patientId': patientId,
                                      'professionalId': professionalId,
                                      'status': 'RESERVADO',
                                    };

                                    await FirebaseFirestore.instance
                                        .collection('appointments')
                                        .add(reservation);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Sesión reservada para $appointmentDay'),
                                      ),
                                    );

                                    setState(() {
                                      selectedDayOfWeek = null;
                                      selectedDate = null;
                                      selectedTime = null;
                                      availableTimes = [];
                                    });
                                  }
                                }
                              : null,
                          icon: Icon(Icons.check, color: Colors.blueAccent),
                          label: Text(
                            'Reservar sesión',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blueAccent),
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                        SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedDayOfWeek = null;
                              selectedDate = null;
                              selectedTime = null;
                              availableTimes = [];
                            });
                          },
                          icon: Icon(Icons.clear, color: Colors.redAccent),
                          label: Text(
                            'Limpiar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.redAccent),
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
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

  Future<List<TimeOfDay>> _getAvailableTimes(String professionalId,
      DateTime selectedDate, Map<String, dynamic> availability) async {
    final List<TimeOfDay> times = [];

    // Obtener las reservas para el día seleccionado
    final reservationsSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('date', isEqualTo: selectedDate.toIso8601String())
        .where('status', isEqualTo: 'RESERVADO')
        .get();

    final reservedTimes = reservationsSnapshot.docs.map((doc) {
      final data = doc.data();
      return _parseTime(data['time']);
    }).toList();

    // Calcular los horarios disponibles
    final startTime = _parseTime(availability['start_time']);
    final endTime = _parseTime(availability['end_time']);
    final breakDuration = availability['break_duration'] as int;

    TimeOfDay currentTime = startTime;
    while (currentTime.hour < endTime.hour ||
        (currentTime.hour == endTime.hour &&
            currentTime.minute < endTime.minute)) {
      // Añadir horario si no está reservado
      if (!reservedTimes.any((reserved) =>
          reserved.hour == currentTime.hour &&
          reserved.minute == currentTime.minute)) {
        times.add(currentTime);
      }
      currentTime = _addMinutes(currentTime, 60 + breakDuration);
    }

    return times;
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      // Divide la cadena en hora y minuto
      final parts = timeString.split(' ');
      final timePart = parts[0].split(':');

      // Analiza la hora y los minutos
      int hour = int.parse(timePart[0]);
      int minute = int.parse(timePart[1]);

      // Maneja el formato AM/PM si es necesario
      if (parts.length > 1) {
        final period = parts[1];
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      // Lanza un error más informativo
      throw FormatException('Formato de hora no válido: $timeString');
    }
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return TimeOfDay(hour: hours % 24, minute: mins);
  }

  List<DateTime> _getAvailableDates(String dayOfWeek, int year, int month) {
    List<DateTime> dates = [];
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
    DateTime today = DateTime.now();

    for (DateTime date = firstDayOfMonth;
        date.isBefore(lastDayOfMonth) || date.isAtSameMomentAs(lastDayOfMonth);
        date = date.add(Duration(days: 1))) {
      if (date.weekday == _dayOfWeekToInt(dayOfWeek) && date.isAfter(today)) {
        dates.add(date);
      }
    }

    return dates;
  }

  int _dayOfWeekToInt(String dayOfWeek) {
    switch (dayOfWeek.toLowerCase()) {
      case 'lunes':
        return DateTime.monday;
      case 'martes':
        return DateTime.tuesday;
      case 'miércoles':
        return DateTime.wednesday;
      case 'jueves':
        return DateTime.thursday;
      case 'viernes':
        return DateTime.friday;
      case 'sábado':
        return DateTime.saturday;
      case 'domingo':
        return DateTime.sunday;
      default:
        throw ArgumentError('Invalid day of week: $dayOfWeek');
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
        throw ArgumentError('Invalid weekday: $weekday');
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
        throw ArgumentError('Invalid month: $month');
    }
  }
}
