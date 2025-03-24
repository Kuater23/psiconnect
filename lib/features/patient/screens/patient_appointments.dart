import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:Psiconnect/navigation/router.dart';
import 'package:intl/date_symbol_data_local.dart';

class PatientAppointments extends StatefulWidget {
  @override
  _PatientAppointmentsState createState() => _PatientAppointmentsState();
}

class _PatientAppointmentsState extends State<PatientAppointments> with TickerProviderStateMixin {
  // Get the current patient ID from Firebase Auth
  String? get currentPatientId => FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize date formatting for Spanish locale
    initializeDateFormatting('es', null);
    _tabController = TabController(length: 2, vsync: this); // Changed from 3 to 2
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Citas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Próximas'),
            Tab(text: 'Historial'), // Changed 'Pasadas' to 'Historial' which makes more sense now
          ],
          indicatorColor: primaryColor,
          labelColor: isDarkMode ? Colors.white : primaryColor,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Menú del Paciente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
                GoRouterHelper(context).go('/patient');
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Solicitar Cita'),
              onTap: () {
                Navigator.pop(context);
                GoRouterHelper(context).go('/patient/book');
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Mis Citas'),
              selected: true,
              selectedTileColor: primaryColor.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Cerrar Sesión'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                GoRouterHelper(context).go('/login');
              },
            ),
          ],
        ),
      ),
      body: currentPatientId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'No has iniciado sesión',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => GoRouterHelper(context).go('/login'),
                    child: Text('Iniciar Sesión'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [              
                _buildAppointmentsList(
                  where: [
                    ['patientId', '==', currentPatientId],
                    ['status', '==', 'scheduled'],
                  ],
                  orderBy: ['appointmentDateTime', false],
                  emptyMessage: 'No tienes citas programadas',
                ),
                
                // Past appointments - show all completed appointments
                _buildAppointmentsList(
                  where: [
                    ['patientId', '==', currentPatientId],
                    ['status', '==', 'completed'],
                  ],
                  orderBy: ['appointmentDateTime', false],
                  emptyMessage: 'No tienes historial de citas completadas',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouterHelper(context).go('/patient/book');
        },
        child: Icon(Icons.add),
        tooltip: 'Solicitar nueva cita',
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget _buildAppointmentsList({
  required List<List<dynamic>> where,
  required List<dynamic> orderBy,
  required String emptyMessage,
}) {
  // Simple query builder that should work without complex indexes
  Query query = FirebaseFirestore.instance.collection('appointments');
  
  // Apply basic filters
  for (var condition in where) {
    if (condition.length >= 3) {
      String field = condition[0];
      String operator = condition[1];
      dynamic value = condition[2];
      
      // Basic equality filter
      if (operator == '==') {
        query = query.where(field, isEqualTo: value);
      }
    }
  }
  
  // Apply orderBy after all where clauses
  query = query.orderBy(orderBy[0], descending: orderBy[1] as bool);
  
  // Debug logging
  print('Querying appointments for patient: $currentPatientId');
  
  return StreamBuilder<QuerySnapshot>(
    stream: query.snapshots(),
    builder: (context, snapshot) {
      // Debug information
      if (snapshot.hasData) {
        print('Found ${snapshot.data!.docs.length} appointments');
      }
      
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        print('Error in query: ${snapshot.error}');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error al cargar las citas: ${snapshot.error}',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () {
                  setState(() {}); // Simple refresh attempt
                },
                child: Text('Reintentar'),
              ),
            ],
          ),
        );
      }
      
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 56, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  GoRouterHelper(context).go('/patient/book');
                },
                icon: Icon(Icons.add),
                label: Text('Solicitar Nueva Cita'),
              ),
            ],
          ),
        );
      }
      
      final appointments = snapshot.data!.docs;
      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index].data() as Map<String, dynamic>;
          final appointmentId = appointments[index].id;
          Timestamp timestamp = appointment['appointmentDateTime'];
          DateTime dateTime = timestamp.toDate();
          
          // Format date and time
          String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(dateTime);
          formattedDate = formattedDate.substring(0, 1).toUpperCase() + formattedDate.substring(1);
          String formattedTime = DateFormat('HH:mm', 'es').format(dateTime);
          
          // Determine status color and text
          Color statusColor;
          String statusText;
          switch (appointment['status']) {
            case 'scheduled':
              statusColor = Colors.green;
              statusText = 'Programada';
              break;
            case 'completed':
              statusColor = Colors.blue;
              statusText = 'Completada';
              break;
            case 'cancelled':
              statusColor = Colors.red;
              statusText = 'Cancelada';
              break;
            default:
              statusColor = Colors.orange;
              statusText = 'Pendiente';
          }
          
          // Add cancellation info directly to the card
          bool canCancel = appointment['status'] == 'scheduled' && _canCancelAppointment(dateTime);

          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    radius: 25,
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    appointment['doctorName'] ?? 'Doctor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: appointment['doctorSpeciality'] != null
                      ? Text(
                          appointment['doctorSpeciality'],
                          style: TextStyle(fontStyle: FontStyle.italic),
                        )
                      : null,
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "Hora: $formattedTime",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                if (appointment['status'] == 'scheduled' && !canCancel)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Esta cita no puede ser cancelada porque está programada para dentro de menos de 48 horas.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (appointment['status'] == 'scheduled')
                  Padding(
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!canCancel)
                          Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Text(
                              'No se puede cancelar (menos de 48 horas)',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        TextButton.icon(
                          onPressed: canCancel 
                            ? () {
                                _showCancelDialog(context, appointmentId);
                              } 
                            : null, // Disable button if can't cancel
                          icon: Icon(Icons.cancel),
                          label: Text('Cancelar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            // Make it appear disabled if cancellation not allowed
                            disabledForegroundColor: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}


// First, add a helper method to check if appointment can be cancelled (48-hour rule)
bool _canCancelAppointment(DateTime appointmentDateTime) {
  // Get current time
  final now = DateTime.now();
  
  // Calculate the difference in hours
  final difference = appointmentDateTime.difference(now).inHours;
  
  // Return true if more than 48 hours remain before the appointment
  return difference > 48;
}

// Update the cancel dialog to be more informative
void _showCancelDialog(BuildContext context, String appointmentId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cancelar Cita'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Estás seguro que deseas cancelar esta cita?'),
          SizedBox(height: 12),
          Text(
            'Nota: Una vez cancelada, no podrás recuperar esta cita.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('No, mantener cita'),
        ),
        ElevatedButton(
          onPressed: () {
            // Close dialog first
            Navigator.of(context).pop();
            // Then cancel - this avoids UI jank if there's an error
            _cancelAppointment(appointmentId);
          },
          child: Text('Sí, cancelar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// Update the _cancelAppointment method to delete the document instead of updating it
Future<void> _cancelAppointment(String appointmentId) async {
  try {
    // First, get the appointment data to check the 48-hour rule
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .get();
    
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La cita no existe o ya fue eliminada'))
      );
      return;
    }
    
    final appointmentData = doc.data() as Map<String, dynamic>;
    final Timestamp timestamp = appointmentData['appointmentDateTime'];
    final DateTime appointmentDateTime = timestamp.toDate();
    
    // Double-check the 48-hour rule
    if (!_canCancelAppointment(appointmentDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede cancelar citas a menos de 48 horas de su inicio'),
          backgroundColor: Colors.orange.shade800,
        )
      );
      return;
    }
    
    // Delete the appointment document completely
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .delete();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cita cancelada exitosamente'),
        backgroundColor: Colors.green,
      )
    );
    
    // Force refresh of the UI
    setState(() {});
    
  } catch (e) {
    print('Error cancelling appointment: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al cancelar la cita: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
} // Closing bracket for _cancelAppointment method
} // Closing bracket for _PatientAppointmentsState class