import 'package:Psiconnect/features/patient/screens/patient_appointments.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Página para solicitar citas
class PatientBookSchedule extends StatefulWidget {
  @override
  _PatientBookScheduleState createState() => _PatientBookScheduleState();
}

class _PatientBookScheduleState extends State<PatientBookSchedule> {
  int currentStep = 0;
  List<Map<String, dynamic>> doctors = [];
  Map<String, dynamic>? selectedDoctor;
  DateTime? selectedDay;
  TimeOfDay? selectedTime;

  // Simulamos el id del paciente actual. Reemplázalo por la lógica de autenticación.
  final String currentPatientId = 'patient123';

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  // Obtiene la lista de doctores con sus parámetros de disponibilidad.
  Future<void> _fetchDoctors() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('doctors').get();
      setState(() {
        doctors = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
            'specialty': data['specialty'] ?? '',
            // workDays: lista de números (1=lunes ... 7=domingo)
            'workDays': data['workDays'],
            // Horario de atención (se asume que se guardan como números enteros)
            'startTime': data['startTime'] ?? 9,
            'endTime': data['endTime'] ?? 17,
            // Duración del receso en minutos
            'breakDuration': data['breakDuration'] ?? 60,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching doctors: $e');
    }
  }

  // Genera los próximos 7 días y filtra aquellos que el doctor atiende.
  List<DateTime> getAvailableDays() {
    final now = DateTime.now();
    List<DateTime> days = List.generate(
      7,
      (index) =>
          DateTime(now.year, now.month, now.day).add(Duration(days: index)),
    );
    if (selectedDoctor != null && selectedDoctor!['workDays'] != null) {
      List<dynamic> workDays = selectedDoctor!['workDays'];
      days = days.where((day) => workDays.contains(day.weekday)).toList();
    }
    return days;
  }

  // Genera los horarios disponibles según el horario laboral y el receso.
  // Se asume que cada cita dura 60 minutos.
  List<TimeOfDay> getAvailableTimes() {
    int startHour = selectedDoctor?['startTime'] ?? 9;
    int endHour = selectedDoctor?['endTime'] ?? 17;
    int breakDuration = selectedDoctor?['breakDuration'] ?? 60;

    int totalWorkingMinutes = (endHour - startHour) * 60;
    // Se posiciona el receso en el centro del intervalo laboral.
    int breakStartMinutes =
        startHour * 60 + (totalWorkingMinutes - breakDuration) ~/ 2;
    int breakEndMinutes = breakStartMinutes + breakDuration;

    List<TimeOfDay> times = [];
    // Se generan slots de 60 minutos.
    for (int slotStart = startHour * 60;
        slotStart <= (endHour * 60) - 60;
        slotStart += 60) {
      // Se descarta el slot si se cruza con el receso.
      if (slotStart < breakEndMinutes && (slotStart + 60) > breakStartMinutes) {
        continue;
      }
      int hour = slotStart ~/ 60;
      int minute = slotStart % 60;
      times.add(TimeOfDay(hour: hour, minute: minute));
    }
    return times;
  }

  // Consulta en Firestore los horarios ya reservados para el doctor en el día seleccionado.
  Future<List<TimeOfDay>> _getReservedTimes() async {
    if (selectedDoctor == null || selectedDay == null) return [];
    DateTime dayStart = DateTime(
        selectedDay!.year, selectedDay!.month, selectedDay!.day);
    DateTime dayEnd = dayStart.add(Duration(days: 1));
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: selectedDoctor!['id'])
        .where('appointmentDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('appointmentDateTime',
            isLessThan: Timestamp.fromDate(dayEnd))
        .get();
    List<TimeOfDay> reserved = snapshot.docs.map((doc) {
      Timestamp timestamp = doc['appointmentDateTime'];
      DateTime dt = timestamp.toDate();
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    }).toList();
    return reserved;
  }

  // Al confirmar, se almacena la cita en Firestore y se agrega el id y nombre del paciente.
  Future<void> _confirmAppointment() async {
    if (selectedDoctor == null || selectedDay == null || selectedTime == null)
      return;
    DateTime appointmentDateTime = DateTime(
      selectedDay!.year,
      selectedDay!.month,
      selectedDay!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': currentPatientId,
        'doctorId': selectedDoctor!['id'],
        'doctorName': selectedDoctor!['name'],
        'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('¡Cita confirmada!')));
      // Reiniciamos el proceso.
      setState(() {
        currentStep = 0;
        selectedDoctor = null;
        selectedDay = null;
        selectedTime = null;
      });
    } catch (e) {
      print('Error confirming appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar la cita. Intente nuevamente.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitar Cita'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('Menú',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Solicitar Cita'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Mis Citas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PatientAppointments()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stepper(
        currentStep: currentStep,
        onStepTapped: (step) => setState(() => currentStep = step),
        onStepContinue: () async {
          if (currentStep == 0 && selectedDoctor == null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Seleccione un doctor')));
            return;
          }
          if (currentStep == 1 && selectedDay == null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Seleccione un día')));
            return;
          }
          if (currentStep == 2 && selectedTime == null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Seleccione una hora')));
            return;
          }
          if (currentStep < 3) {
            setState(() {
              currentStep++;
            });
          } else {
            await _confirmAppointment();
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() {
              currentStep--;
            });
          }
        },
        steps: [
          // Paso 1: Seleccionar doctor.
          Step(
            title: Text('Doctor'),
            content: doctors.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return ListTile(
                          title: Text(doctor['name']),
                          subtitle: Text(doctor['specialty']),
                          selected: selectedDoctor != null &&
                              selectedDoctor!['id'] == doctor['id'],
                          onTap: () {
                            setState(() {
                              selectedDoctor = doctor;
                              // Reiniciamos día y hora al cambiar de doctor.
                              selectedDay = null;
                              selectedTime = null;
                            });
                          },
                        );
                      },
                    ),
                  ),
            isActive: currentStep >= 0,
            state: selectedDoctor == null
                ? StepState.editing
                : StepState.complete,
          ),
          // Paso 2: Seleccionar día.
          Step(
            title: Text('Día'),
            content: Container(
              height: 200,
              child: ListView.builder(
                itemCount: getAvailableDays().length,
                itemBuilder: (context, index) {
                  final day = getAvailableDays()[index];
                  return ListTile(
                    title: Text(DateFormat('EEEE, MMM d').format(day)),
                    selected: selectedDay != null &&
                        DateFormat('yyyy-MM-dd').format(selectedDay!) ==
                            DateFormat('yyyy-MM-dd').format(day),
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                        selectedTime = null;
                      });
                    },
                  );
                },
              ),
            ),
            isActive: currentStep >= 1,
            state: selectedDay == null
                ? StepState.editing
                : StepState.complete,
          ),
          // Paso 3: Seleccionar hora.
          Step(
            title: Text('Hora'),
            content: FutureBuilder<List<TimeOfDay>>(
              future: _getReservedTimes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return Center(
                      child: Text('Error al cargar horarios reservados'));
                final reservedTimes = snapshot.data ?? [];
                // Filtra los horarios disponibles descartando los ya reservados.
                final times = getAvailableTimes()
                    .where((time) => !reservedTimes.any((reserved) =>
                        reserved.hour == time.hour &&
                        reserved.minute == time.minute))
                    .toList();
                if (times.isEmpty)
                  return Center(child: Text('No hay horarios disponibles'));
                return Container(
                  height: 200,
                  child: ListView.builder(
                    itemCount: times.length,
                    itemBuilder: (context, index) {
                      final time = times[index];
                      return ListTile(
                        title: Text(time.format(context)),
                        selected: selectedTime != null &&
                            selectedTime!.hour == time.hour &&
                            selectedTime!.minute == time.minute,
                        onTap: () {
                          setState(() {
                            selectedTime = time;
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
            isActive: currentStep >= 2,
            state: selectedTime == null
                ? StepState.editing
                : StepState.complete,
          ),
          // Paso 4: Confirmar la cita.
          Step(
            title: Text('Confirmar'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctor: ${selectedDoctor?['name'] ?? ''}'),
                Text('Día: ${selectedDay != null ? DateFormat('EEEE, MMM d').format(selectedDay!) : ''}'),
                Text('Hora: ${selectedTime?.format(context) ?? ''}'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _confirmAppointment,
                  child: Text('Confirmar Cita'),
                ),
              ],
            ),
            isActive: currentStep >= 3,
            state: StepState.complete,
          ),
        ],
      ),
    );
  }
}
