import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Reutiliza el menú hamburguesa

class PatientAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda de Pacientes'),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ],
      ),
      drawer: SharedDrawer(), // Reutiliza el menú hamburguesa
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SolicitarCitaPage()),
            );
          },
          child: Text('Solicitar Cita'),
        ),
      ),
    );
  }
}

class SolicitarCitaPage extends StatefulWidget {
  @override
  _SolicitarCitaPageState createState() => _SolicitarCitaPageState();
}

class _SolicitarCitaPageState extends State<SolicitarCitaPage> {
  String? selectedProfessional;
  DateTime? selectedDate;
  String? selectedTime;
  List<DateTime> availableDates = [];
  List<String> availableTimes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitar Cita'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de profesional
            Text(
              'Selecciona un profesional:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'professional')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                final professionals = snapshot.data!.docs;

                return DropdownButton<String>(
                  hint: Text('Selecciona un profesional'),
                  value: selectedProfessional,
                  items: professionals.map((doc) {
                    final docData = doc.data() as Map<String, dynamic>;
                    final name = docData['name'] ?? 'No name';
                    final lastName = docData['lastName'] ?? '';
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text('$name $lastName'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProfessional = value;
                      _loadAvailableDates(value!); // Cargar fechas disponibles
                    });
                  },
                );
              },
            ),
            SizedBox(height: 20),

            // Selector de fecha
            if (availableDates.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona una fecha:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<DateTime>(
                    hint: Text('Selecciona una fecha'),
                    value: selectedDate,
                    items: availableDates.map((date) {
                      return DropdownMenuItem<DateTime>(
                        value: date,
                        child:
                            Text(DateFormat('EEEE, dd/MM/yyyy').format(date)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDate = value;
                        _loadAvailableTimes(selectedProfessional!, value!);
                      });
                    },
                  ),
                ],
              ),
            SizedBox(height: 20),

            // Selector de hora
            if (availableTimes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona una hora:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    hint: Text('Selecciona una hora'),
                    value: selectedTime,
                    items: availableTimes.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTime = value;
                      });
                    },
                  ),
                ],
              ),
            SizedBox(height: 20),

            // Botón para solicitar la cita
            ElevatedButton(
              onPressed: selectedProfessional != null &&
                      selectedDate != null &&
                      selectedTime != null
                  ? _submitAppointment
                  : null,
              child: Text('Solicitar Cita'),
            ),
          ],
        ),
      ),
    );
  }

  // Cargar las fechas disponibles en función de los días de la semana
  void _loadAvailableDates(String professionalId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(professionalId)
        .get();

    final availability =
        (doc.data()?['availability']['days'] ?? []) as List<dynamic>;

    List<DateTime> dates = [];
    DateTime today = DateTime.now();
    for (int i = 0; i < 30; i++) {
      DateTime date = today.add(Duration(days: i));
      String dayOfWeek = DateFormat('EEEE', 'es').format(date);
      if (availability.contains(dayOfWeek)) {
        dates.add(date);
      }
    }

    setState(() {
      availableDates = dates;
    });
  }

  // Cargar las horas disponibles basadas en las citas reservadas
  void _loadAvailableTimes(String professionalId, DateTime date) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(professionalId)
        .get();

    final availability = doc.data()?['availability'];

    // Obtener las citas ya reservadas
    final reservedAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('date', isEqualTo: DateFormat('dd/MM/yyyy').format(date))
        .get();

    List<String> reservedTimes = reservedAppointments.docs.map((doc) {
      return doc['slot'] as String;
    }).toList();

    // Generar la lista de horas disponibles
    List<String> times = [];
    TimeOfDay startTime = TimeOfDay(
      hour: int.parse(availability['start_time'].split(':')[0]),
      minute: int.parse(availability['start_time'].split(':')[1]),
    );
    TimeOfDay endTime = TimeOfDay(
      hour: int.parse(availability['end_time'].split(':')[0]),
      minute: int.parse(availability['end_time'].split(':')[1]),
    );

    for (int hour = startTime.hour; hour < endTime.hour; hour++) {
      String timeSlot = '$hour:00';
      if (!reservedTimes.contains(timeSlot)) {
        times.add(timeSlot);
      }
    }

    setState(() {
      availableTimes = times;
    });
  }

  // Guardar la cita en Firebase
  Future<void> _submitAppointment() async {
    final appointmentData = {
      'patientId': FirebaseAuth.instance.currentUser!.uid,
      'professionalId': selectedProfessional,
      'date': DateFormat('dd/MM/yyyy').format(selectedDate!),
      'slot': selectedTime,
      'status': 'Reservado',
      'created_at': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection('appointments')
        .add(appointmentData);

    // Redirigir o mostrar mensaje de éxito
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Cita solicitada exitosamente'),
    ));
  }
}
