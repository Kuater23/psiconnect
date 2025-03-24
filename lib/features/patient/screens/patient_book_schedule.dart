import 'package:Psiconnect/features/patient/screens/patient_appointments.dart';
import 'package:Psiconnect/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:Psiconnect/navigation/shared_drawer.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';

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
  bool isLoading = false;
  String? errorMessage;
  final _appointmentCompletedController = StreamController<bool>.broadcast();
  
  // Obtener ID del paciente actual desde Firebase Auth
  String? get currentPatientId => FirebaseAuth.instance.currentUser?.uid;

  // Mapa para convertir abreviaturas de días a números de día de la semana
  final Map<String, int> dayToWeekday = {
    'Lun': DateTime.monday,
    'Mar': DateTime.tuesday,
    'Mié': DateTime.wednesday,
    'Jue': DateTime.thursday,
    'Vie': DateTime.friday,
    'Sáb': DateTime.saturday,
    'Dom': DateTime.sunday,
  };

  @override
  void initState() {
    super.initState();
    // Initialize date formatting for Spanish locale before using it
    initializeDateFormatting('es', null).then((_) {
      // After initialization, fetch doctors
      _fetchDoctors();
    });
  }

  @override
  void dispose() {
    _appointmentCompletedController.close();
    super.dispose();
  }

  // Obtener la lista de doctores desde Firestore
  Future<void> _fetchDoctors() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('doctors').get();
      
      if (mounted) {
        setState(() {
          doctors = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Obtener días de trabajo como lista de strings (Lun, Mar, etc.)
            List<String> workDaysList = [];
            if (data['workDays'] != null) {
              if (data['workDays'] is List) {
                workDaysList = List<String>.from(data['workDays']);
              }
            }
            
            // Handle startTime and endTime as strings or convert from int
            var startTime = data['startTime'];
            var endTime = data['endTime'];
            
            // Convert to integers if they're strings in HH:MM format
            int startHour = startTime is String ? 
                int.tryParse(startTime.split(':')[0]) ?? 9 : 
                (startTime is int ? startTime : 9);
                
            int endHour = endTime is String ? 
                int.tryParse(endTime.split(':')[0]) ?? 17 : 
                (endTime is int ? endTime : 17);
            
            return {
              'id': doc.id,
              'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
              'speciality': data['speciality'] ?? 'Sin especialidad', // Fix: changed 'speciality' to 'speciality' to match Firestore field
              'photoUrl': data['photoUrl'],
              'workDays': workDaysList, // Lista de strings como "Lun", "Mar", etc.
              'startTime': startHour, // Now consistently stored as integer
              'endTime': endHour,    // Now consistently stored as integer
              'breakDuration': data['breakDuration'] ?? 60,
            };
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar la lista de doctores: $e';
        });
        print('Error fetching doctors: $e');
      }
    }
  }

  // Generar días disponibles basados en el horario del doctor
  List<DateTime> getAvailableDays() {
    final now = DateTime.now();
    List<DateTime> days = List.generate(
      14, // Mostrar las próximas 2 semanas
      (index) => DateTime(now.year, now.month, now.day).add(Duration(days: index)),
    );
    
    if (selectedDoctor != null && selectedDoctor!['workDays'] != null) {
      List<String> workDays = List<String>.from(selectedDoctor!['workDays']);
      List<int> workDayNumbers = workDays.map((day) => dayToWeekday[day] ?? 0).toList();
      
      // Filtrar solo los días que coinciden con los días laborables del doctor
      days = days.where((day) => workDayNumbers.contains(day.weekday)).toList();
    }
    
    return days;
  }

  // Generar horarios disponibles para citas
  List<TimeOfDay> getAvailableTimes() {
    int startHour = selectedDoctor?['startTime'] ?? 9;
    int endHour = selectedDoctor?['endTime'] ?? 17;
    int breakDuration = selectedDoctor?['breakDuration'] ?? 60;

    int totalWorkingMinutes = (endHour - startHour) * 60;
    int breakStartMinutes = startHour * 60 + (totalWorkingMinutes - breakDuration) ~/ 2;
    int breakEndMinutes = breakStartMinutes + breakDuration;

    List<TimeOfDay> times = [];
    // Generar slots de 60 minutos
    for (int slotStart = startHour * 60; slotStart <= (endHour * 60) - 60; slotStart += 60) {
      if (slotStart < breakEndMinutes && (slotStart + 60) > breakStartMinutes) {
        continue; // Saltar slots que se solapan con el descanso
      }
      int hour = slotStart ~/ 60;
      int minute = slotStart % 60;
      times.add(TimeOfDay(hour: hour, minute: minute));
    }
    
    return times;
  }

  // Obtener horarios ya reservados
  Future<List<TimeOfDay>> _getReservedTimes() async {
    if (selectedDoctor == null || selectedDay == null) return [];
    
    try {
      DateTime dayStart = DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day);
      DateTime dayEnd = dayStart.add(Duration(days: 1));
      
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: selectedDoctor!['id'])
          .where('appointmentDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('appointmentDateTime', isLessThan: Timestamp.fromDate(dayEnd))
          .get();
      
      List<TimeOfDay> reserved = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        Timestamp timestamp = data['appointmentDateTime'];
        DateTime dt = timestamp.toDate();
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      }).toList();
      
      return reserved;
    } catch (e) {
      print('Error getting reserved times: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar horarios disponibles'))
      );
      return [];
    }
  }

  // Confirmar y guardar la cita
  Future<void> _confirmAppointment() async {
    // Get the current user ID once at the start of the function and store it
    final String? patientId = FirebaseAuth.instance.currentUser?.uid;
    
    if (selectedDoctor == null || selectedDay == null || selectedTime == null || patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Información incompleta o no ha iniciado sesión'))
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // Obtain patient information
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId) // Use the stored patientId
          .get();
      
      String patientName = '';
      if (patientDoc.exists) {
        final patientData = patientDoc.data() as Map<String, dynamic>;
        patientName = '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}';
      }
      
      // Create date time with the selected day and time
      DateTime appointmentDateTime = DateTime(
        selectedDay!.year,
        selectedDay!.month,
        selectedDay!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      
      // Format time as HH:MM for Firestore
      String formattedTime = _formatTime(selectedTime!);
      
      // Create a document reference first to get the ID before writing
      DocumentReference docRef = FirebaseFirestore.instance.collection('appointments').doc();
      
      // Now add the data including the document ID as appointmentId
      await docRef.set({
        'appointmentId': docRef.id,
        'patientId': patientId, // Use the stored patientId
        'patientName': patientName,
        'doctorId': selectedDoctor!['id'],
        'doctorName': selectedDoctor!['name'],
        'doctorSpeciality': selectedDoctor!['speciality'],
        'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
        'appointmentTime': formattedTime,
        'appointmentDate': DateFormat('yyyy-MM-dd').format(selectedDay!),
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // Add to the stream to show success screen
        _appointmentCompletedController.add(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        print('Error confirming appointment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al confirmar la cita. Intente nuevamente.'))
        );
      }
    }
  }

  // Métodos para UI

  // Formatear fecha
  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM', 'es').format(date);
  }
  
  // Formatear hora con periodo (AM/PM)
  String _formatTime(TimeOfDay time) {
    // Format as HH:MM to match database format
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
  
  // Convertir lista de días abreviados a texto legible
  String formatWorkDays(List<String> workDays) {
    if (workDays.isEmpty) return 'No especificado';
    
    return workDays.join(', ');
  }
  
  // Formatear horario de trabajo
  String formatWorkingHours(int start, int end) {
    // Format time correctly using padLeft
    final startFormatted = start.toString().padLeft(2, '0') + ':00';
    final endFormatted = end.toString().padLeft(2, '0') + ':00';
    return '$startFormatted - $endFormatted';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _appointmentCompletedController.stream,
      builder: (context, snapshot) {
        // If appointment is completed, show a success screen instead of trying to navigate
        if (snapshot.hasData && snapshot.data == true) {
          return _buildSuccessScreen(context);
        }
        
        // Your normal UI when not completed
        return Scaffold(
          appBar: AppBar(
            title: Text('Solicitar Cita'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          drawer: SharedDrawer(), // Usando drawer compartido
          body: isLoading && doctors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando información...'),
                    ],
                  ),
                )
              : errorMessage != null && doctors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline, 
                            size: 48, 
                            color: Theme.of(context).colorScheme.error
                          ),
                          SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchDoctors,
                            child: Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildBookingUI(),
        );
      }
    );
  }

  Widget _buildBookingUI() {
    // Detectar tema oscuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
            ),
      ),
      child: Stepper(
        type: StepperType.vertical,
        physics: ScrollPhysics(),
        currentStep: currentStep,
        onStepTapped: (step) => setState(() => currentStep = step),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (details.currentStep > 0)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text('Atrás'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                if (details.currentStep > 0) SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : details.onStepContinue,
                    child: Text(
                      details.currentStep == 3
                          ? 'Confirmar Cita'
                          : 'Continuar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDarkMode ? Colors.white : Colors.white,
                      disabledBackgroundColor: isDarkMode 
                          ? Colors.grey.shade700 
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        onStepContinue: () async {
          // Validación para cada paso
          if (currentStep == 0 && selectedDoctor == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Por favor, seleccione un doctor'))
            );
            return;
          }
          if (currentStep == 1 && selectedDay == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Por favor, seleccione un día'))
            );
            return;
          }
          if (currentStep == 2 && selectedTime == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Por favor, seleccione una hora'))
            );
            return;
          }

          if (currentStep < 3) {
            setState(() {
              currentStep += 1;
            });
          } else {
            await _confirmAppointment();
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() {
              currentStep -= 1;
            });
          }
        },
        steps: [
          // Paso 1: Seleccionar doctor
          Step(
            title: Text('Seleccionar Doctor'),
            content: doctors.isEmpty
                ? Center(child: Text('No hay doctores disponibles'))
                : Container(
                    height: 400, // Altura mayor para mostrar más información
                    child: ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        bool isSelected = selectedDoctor != null &&
                            selectedDoctor!['id'] == doctor['id'];
                        
                        // Convertir workDays a texto legible
                        List<String> workDays = List<String>.from(doctor['workDays'] ?? []);
                        String workDaysText = formatWorkDays(workDays);
                        String workHoursText = formatWorkingHours(
                          doctor['startTime'] ?? 9, 
                          doctor['endTime'] ?? 17
                        );
                        
                        return Card(
                          elevation: isSelected ? 4 : 1,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          color: isSelected
                              ? isDarkMode
                                  ? primaryColor.withOpacity(0.2)
                                  : primaryColor.withOpacity(0.1)
                              : cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedDoctor = doctor;
                                selectedDay = null;
                                selectedTime = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: isSelected
                                            ? primaryColor.withOpacity(0.3)
                                            : isDarkMode 
                                                ? Colors.grey.shade800 
                                                : Colors.grey.withOpacity(0.2),
                                        backgroundImage: doctor['photoUrl'] != null
                                            ? NetworkImage(doctor['photoUrl'])
                                            : null,
                                        child: doctor['photoUrl'] == null
                                            ? Text(
                                                doctor['name'].isNotEmpty
                                                    ? doctor['name'][0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? primaryColor
                                                      : isDarkMode 
                                                          ? Colors.white70 
                                                          : Colors.grey.shade700,
                                                ),
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doctor['name'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode ? Colors.white : textColor,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              doctor['speciality'] ?? 'Especialidad no especificada',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.arrow_forward_ios,
                                        color: isSelected
                                            ? primaryColor
                                            : isDarkMode ? Colors.white60 : Colors.grey,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDarkMode 
                                          ? Colors.grey.shade800.withOpacity(0.5) 
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18,
                                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Días de atención: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                workDaysText,
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors.white : textColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 18,
                                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Horario: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              workHoursText,
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white : textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            isActive: currentStep >= 0,
            state: selectedDoctor == null
                ? StepState.indexed
                : StepState.complete,
          ),
          
          // Paso 2: Seleccionar día
          Step(
            title: Text('Seleccionar Día'),
            content: selectedDoctor == null
                ? Center(child: Text('Primero seleccione un doctor'))
                : getAvailableDays().isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay días disponibles para este doctor',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 300,
                        child: ListView.builder(
                          itemCount: getAvailableDays().length,
                          itemBuilder: (context, index) {
                            final day = getAvailableDays()[index];
                            bool isSelected = selectedDay != null &&
                                DateFormat('yyyy-MM-dd').format(selectedDay!) ==
                                    DateFormat('yyyy-MM-dd').format(day);
                            
                            // Verificar si el día es hoy o futuro
                            bool isToday = day.day == DateTime.now().day &&
                                day.month == DateTime.now().month &&
                                day.year == DateTime.now().year;
                            
                            return Card(
                              elevation: isSelected ? 4 : 1,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              color: isSelected
                                  ? isDarkMode
                                      ? primaryColor.withOpacity(0.2)
                                      : primaryColor.withOpacity(0.1)
                                  : cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isSelected
                                    ? BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedDay = day;
                                    selectedTime = null;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor
                                              : isToday
                                                  ? isDarkMode
                                                      ? Colors.blue.withOpacity(0.3)
                                                      : Colors.blue.withOpacity(0.1)
                                                  : isDarkMode
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              day.day.toString(),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? isDarkMode ? Colors.white : Colors.white
                                                    : isToday
                                                        ? isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700
                                                        : isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('MMM', 'es').format(day),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isSelected
                                                    ? isDarkMode ? Colors.white70 : Colors.white
                                                    : isToday
                                                        ? isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700
                                                        : isDarkMode ? Colors.white60 : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('EEEE', 'es').format(day),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode ? Colors.white : textColor,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              isToday
                                                  ? 'Hoy'
                                                  : DateFormat('d, MMMM yyyy', 'es').format(day),
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.arrow_forward_ios,
                                        color: isSelected
                                            ? primaryColor
                                            : isDarkMode ? Colors.white60 : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            isActive: currentStep >= 1,
            state: currentStep > 1
                ? selectedDay == null
                    ? StepState.error
                    : StepState.complete
                : StepState.indexed,
          ),
          
          // Paso 3: Seleccionar hora
          Step(
            title: Text('Seleccionar Hora'),
            content: selectedDay == null
                ? Center(child: Text('Primero seleccione un día'))
                : FutureBuilder<List<TimeOfDay>>(
                    future: _getReservedTimes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline, 
                                color: Theme.of(context).colorScheme.error, 
                                size: 48
                              ),
                              SizedBox(height: 16),
                              Text('Error al cargar horarios disponibles'),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {}); // Refrescar
                                },
                                child: Text('Reintentar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final reservedTimes = snapshot.data ?? [];
                      // Filtrar horarios disponibles que no estén reservados
                      final times = getAvailableTimes()
                          .where((time) => !reservedTimes.any((reserved) =>
                              reserved.hour == time.hour &&
                              reserved.minute == time.minute))
                          .toList();
                      
                      if (times.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy, 
                                color: isDarkMode ? Colors.orange.shade300 : Colors.orange, 
                                size: 48
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay horarios disponibles para este día',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white70 : Colors.grey.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedDay = null;
                                    currentStep = 1; // Volver a selección de día
                                  });
                                },
                                child: Text('Seleccionar otro día'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Container(
                        height: 300,
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,  // Changed from 2 to 3 columns
                            childAspectRatio: 1.0,  // Adjusted aspect ratio
                            crossAxisSpacing: 8,   // Reduced spacing
                            mainAxisSpacing: 8,    // Reduced spacing
                          ),
                          itemCount: times.length,
                          itemBuilder: (context, index) {
                            final time = times[index];
                            bool isSelected = selectedTime != null &&
                                selectedTime!.hour == time.hour &&
                                selectedTime!.minute == time.minute;
                            
                            return Card(
                              elevation: isSelected ? 3 : 1,
                              margin: EdgeInsets.zero,  // Remove card margin
                              color: isSelected
                                  ? isDarkMode
                                      ? primaryColor.withOpacity(0.3)
                                      : primaryColor.withOpacity(0.1)
                                  : cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),  // Smaller radius
                                side: isSelected
                                    ? BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedTime = time;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Text(
                                    _formatTime(time),
                                    style: TextStyle(
                                      fontSize: 14,  // Smaller font
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? primaryColor
                                          : isDarkMode ? Colors.white : textColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
            isActive: currentStep >= 2,
            state: currentStep > 2
                ? selectedTime == null
                    ? StepState.error
                    : StepState.complete
                : StepState.indexed,
          ),
          
          // Paso 4: Confirmar cita
          Step(
            title: Text('Confirmar Cita'),
            content: Column(
              children: [
                Card(
                  elevation: 4,
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: isDarkMode
                                  ? primaryColor.withOpacity(0.3)
                                  : primaryColor.withOpacity(0.2),
                              backgroundImage: selectedDoctor?['photoUrl'] != null
                                  ? NetworkImage(selectedDoctor!['photoUrl'])
                                  : null,
                              child: selectedDoctor?['photoUrl'] == null
                                  ? Text(
                                      selectedDoctor?['name']?.isNotEmpty == true
                                          ? selectedDoctor!['name'][0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cita con',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    selectedDoctor?['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : textColor,
                                    ),
                                  ),
                                  Text(
                                    selectedDoctor?['speciality'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white70 : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 32, 
                          color: isDarkMode ? Colors.white24 : Colors.grey.shade300
                        ),
                        _appointmentDetailRow(
                          icon: Icons.calendar_today,
                          title: 'Fecha',
                          value: selectedDay != null
                              ? _formatDate(selectedDay!)
                              : 'No seleccionada',
                          isDarkMode: isDarkMode,
                          primaryColor: primaryColor,
                        ),
                        SizedBox(height: 16),
                        _appointmentDetailRow(
                          icon: Icons.access_time,
                          title: 'Hora',
                          value: selectedTime != null
                              ? _formatTime(selectedTime!)
                              : 'No seleccionada',
                          isDarkMode: isDarkMode,
                          primaryColor: primaryColor,
                        ),
                        SizedBox(height: 16),
                        _appointmentDetailRow(
                          icon: Icons.schedule,
                          title: 'Duración',
                          value: '60 minutos',
                          isDarkMode: isDarkMode,
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                if (isLoading)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Procesando su cita...',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            isActive: currentStep >= 3,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }
  
  // Método auxiliar para detalles de cita en paso de confirmación
  Widget _appointmentDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? primaryColor.withOpacity(0.2)
                : primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryColor,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Add a success screen widget that shows after completion
  Widget _buildSuccessScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cita Confirmada'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            SizedBox(height: 20),
            Text(
              '¡Cita confirmada correctamente!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Tu cita ha sido programada con éxito.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // This is safer since we're not in an async callback
                context.go('/patient/appointments');
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'Ver Mis Citas',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}