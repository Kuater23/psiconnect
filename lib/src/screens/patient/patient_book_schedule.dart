import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientBookSchedule extends StatefulWidget {
  @override
  _PatientBookScheduleState createState() => _PatientBookScheduleState();
}

class _PatientBookScheduleState extends State<PatientBookSchedule> {
  String? selectedDay;
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
      backgroundColor: Color.fromRGBO(2, 60, 67, 1),
      appBar: AppBar(
        title: Text('Agenda de Dr. $lastName, $name'),
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
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
              color: Color.fromRGBO(1, 40, 45, 1),
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dirección: ${professionalData['address']}',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Teléfono: ${professionalData['phone']}',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Disponibilidad:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Selecciona un día',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Color.fromRGBO(2, 60, 67, 0.5),
                      ),
                      dropdownColor: Color.fromRGBO(2, 60, 67, 1),
                      value: selectedDay,
                      onChanged: (String? newValue) async {
                        setState(() {
                          selectedDay = newValue;
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
                      items: (availability['days'] as List<dynamic>)
                          .map<DropdownMenuItem<String>>((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child:
                              Text(day, style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    if (isLoadingTimes)
                      Center(child: CircularProgressIndicator())
                    else if (selectedDay != null) ...[
                      Text(
                        'Horarios disponibles:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<TimeOfDay>(
                        decoration: InputDecoration(
                          labelText: 'Selecciona una hora',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          filled: true,
                          fillColor: Color.fromRGBO(2, 60, 67, 0.5),
                        ),
                        dropdownColor: Color.fromRGBO(2, 60, 67, 1),
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
                                style: TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: selectedDay != null && selectedTime != null
                              ? () async {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    final patientId = user.uid;
                                    final reservation = {
                                      'day': selectedDay,
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
                                            'Sesión reservada para $selectedDay a las ${selectedTime!.format(context)}'),
                                      ),
                                    );

                                    setState(() {
                                      selectedDay = null;
                                      selectedTime = null;
                                      availableTimes = [];
                                    });
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromRGBO(11, 191, 205, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text('Reservar sesión'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedDay = null;
                              selectedTime = null;
                              availableTimes = [];
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text('Limpiar'),
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

  Future<List<TimeOfDay>> _getAvailableTimes(String professionalId,
      String selectedDay, Map<String, dynamic> availability) async {
    final List<TimeOfDay> times = [];

    // Obtener las reservas para el día seleccionado
    final reservationsSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('day', isEqualTo: selectedDay)
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
}
