import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:Psiconnect/src/widgets/shared_drawer.dart'; // Reutiliza el menú hamburguesa
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:intl/date_symbol_data_local.dart'; // Para inicializar la configuración regional



class PatientAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {


    final String? patientId = FirebaseAuth.instance.currentUser?.uid;

    if (patientId == null) {
      return Scaffold(
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        appBar: AppBar(
          title: Text('Agenda Digital'),
          backgroundColor: Color.fromRGBO(2, 60, 67, 1),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          actions: [
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                );
              },
            ),
          ],
        ),
        drawer: SharedDrawer(),
        body: Center(
          child: Text(
            'No se encontró el paciente autenticado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color.fromRGBO(2, 60, 67, 1),
      appBar: AppBar(

        title: Text('Agenda de Pacientes'), 
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),

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
  _ProfessionalAgendaState createState() => _ProfessionalAgendaState();
}

class _ProfessionalAgendaState extends State<ProfessionalAgenda> {
  DateTime _selectedDate = DateTime.now();
  List<DateTime> _weekDays = [];
  DateTime? _selectedDay;
  String? _selectedSlot;
  List<String> _availableSlots = [];
  List<String> _availabilityDays = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null).then((_) {
      _fetchAvailabilityDays();
      _updateWeekDays();
    });
  }

  void _fetchAvailabilityDays() {
    final availability =
        widget.professional['availability'] as Map<String, dynamic>;
    final availabilityDays = availability['days'] as List<dynamic>;
    setState(() {
      _availabilityDays = availabilityDays.cast<String>();
    });
  }

  void _updateWeekDays() {
    _weekDays = [];
    DateTime startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    for (int i = 0; i < 7; i++) {
      _weekDays.add(startOfWeek.add(Duration(days: i)));
    }
  }

  void _previousWeek() {
    setState(() {
      _selectedDate = _selectedDate.subtract(Duration(days: 7));
      _updateWeekDays();
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: 7));
      _updateWeekDays();
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _fetchAvailableSlots(day);
    });
  }

  void _selectSlot(String slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  void _fetchAvailableSlots(DateTime day) async {
    final availability =
        widget.professional['availability'] as Map<String, dynamic>;
    final startTime = availability['start_time'] as String;
    final endTime = availability['end_time'] as String;

    // Obtenemos el nombre del día en español y lo convertimos a minúsculas
    final dayOfWeek = DateFormat('EEEE', 'es_ES').format(day).toLowerCase();

    print('Día seleccionado: $dayOfWeek');
    print('Días disponibles: $_availabilityDays');

    // Verificamos si el día está dentro de los días de disponibilidad
    if (_availabilityDays.map((d) => d.toLowerCase()).contains(dayOfWeek)) {
      final start = TimeOfDay(
        hour: int.parse(startTime.split(':')[0]),
        minute: int.parse(startTime.split(':')[1]),
      );
      final end = TimeOfDay(
        hour: int.parse(endTime.split(':')[0]),
        minute: int.parse(endTime.split(':')[1]),
      );

      print('Horario de inicio: ${start.format(context)}');
      print('Horario de fin: ${end.format(context)}');

      List<String> availableSlots = [];
      TimeOfDay currentTime = start;

      // Creamos intervalos de 50 minutos consecutivos
      while (currentTime.hour < end.hour ||
          (currentTime.hour == end.hour && currentTime.minute < end.minute)) {
        final nextTime = currentTime.replacing(
          hour: currentTime.minute + 50 >= 60
              ? currentTime.hour + 1
              : currentTime.hour,
          minute: (currentTime.minute + 50) % 60,
        );
        availableSlots.add(
            '${currentTime.format(context)} - ${nextTime.format(context)} Modalidad virtual');
        currentTime = nextTime;
      }

      setState(() {
        _availableSlots = availableSlots;
      });
    } else {
      setState(() {
        _availableSlots = [];
      });
    }
  }

  void _bookAppointment() async {
    final String? patientId = FirebaseAuth.instance.currentUser?.uid;
    if (patientId == null || _selectedDay == null || _selectedSlot == null) {
      return;
    }

    final appointment = {
      'patientId': patientId,
      'professionalId': widget.professional.id,
      'date': _selectedDay,
      'slot': _selectedSlot,
      'status': 'Reservado',
    };

    await FirebaseFirestore.instance
        .collection('appointments')
        .add(appointment);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Turno Reservado')),
    );

    setState(() {
      _selectedDay = null;
      _selectedSlot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(2, 60, 67, 1),
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

        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Agenda del Dr. ${widget.professional['lastName']}, ${widget.professional['name']}',
        ),
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Color.fromRGBO(1, 40, 45, 1),
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos de contacto:',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${widget.professional['address']}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.white),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${widget.professional['email']}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.white),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${widget.professional['phone']}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Turnos disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _previousWeek,
                      ),
                      Text(
                        '${DateFormat('d MMM', 'es_ES').format(_weekDays.first)} - ${DateFormat('d MMM', 'es_ES').format(_weekDays.last)}',
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: Colors.white),
                        onPressed: _nextWeek,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Column(
                    children: _availabilityDays.map((day) {
                      final dayDate = _getNextWeekdayDate(day);
                      return ListTile(
                        title: Text(
                          DateFormat('EEEE, d MMM', 'es_ES').format(dayDate),
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Ver horarios',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          _selectDay(dayDate);
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedDay != null) ...[
                    SizedBox(height: 10),
                    Text(
                      'Horarios disponibles para ${DateFormat('EEEE, d MMM', 'es_ES').format(_selectedDay!)}:',
                      style: TextStyle(color: Colors.white),
                    ),
                    Column(
                      children: _availableSlots.map((slot) {
                        return ListTile(
                          title: Text(
                            slot,
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            _selectSlot(slot);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  if (_selectedSlot != null)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: _bookAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(11, 191, 205, 1),
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 10,
                        ),
                        child: Text(
                          'Pedí turno ahora',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime _getNextWeekdayDate(String weekday) {
    final now = DateTime.now();
    final daysOfWeek = {
      'lunes': DateTime.monday,
      'martes': DateTime.tuesday,
      'miércoles': DateTime.wednesday,
      'jueves': DateTime.thursday,
      'viernes': DateTime.friday,
      'sábado': DateTime.saturday,
      'domingo': DateTime.sunday,
    };
    final targetWeekday = daysOfWeek[weekday.toLowerCase()]!;
    final daysToAdd = (targetWeekday - now.weekday + 7) % 7;
    return now.add(Duration(days: daysToAdd));

  }
}
