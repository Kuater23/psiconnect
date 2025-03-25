// lib/features/professional/screens/professional_appointments.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:Psiconnect/navigation/router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/navigation/shared_drawer.dart'; // Importar el drawer compartido

// Cambiar de StatefulWidget a HookConsumerWidget para compatibilidad con Riverpod
class ProfessionalAppointments extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  
  const ProfessionalAppointments({
    Key? key,
    required this.toggleTheme,
  }) : super(key: key);
  
  @override
  ConsumerState<ProfessionalAppointments> createState() => _ProfessionalAppointmentsState();
}

class _ProfessionalAppointmentsState extends ConsumerState<ProfessionalAppointments> with TickerProviderStateMixin {
  // Get the current professional ID from Firebase Auth
  String? get currentDoctorId => FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize date formatting for Spanish locale
    initializeDateFormatting('es', null);
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Gestión de Citas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hoy'),            // Cambiado el orden
            Tab(text: 'Próximas'),
            Tab(text: 'Historial'),
          ],
          indicatorColor: primaryColor,
          labelColor: isDarkMode ? Colors.white : primaryColor,
        ),
      ),
      // Usar el SharedDrawer en lugar del drawer personalizado
      drawer: const SharedDrawer(),
      body: currentDoctorId == null
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
                    onPressed: () => GoRouter.of(context).go('/login'),
                    child: Text('Iniciar Sesión'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Today's appointments
                _buildSimpleAppointmentsList(
                  isToday: true,
                  isUpcoming: false,
                  isPast: false,
                  emptyMessage: 'No tienes citas para hoy',
                  icon: Icons.today,
                ),
                
                // Tab 2: Upcoming appointments (excluding today)
                _buildSimpleAppointmentsList(
                  isToday: false,
                  isUpcoming: true,
                  isPast: false,
                  emptyMessage: 'No tienes citas próximas',
                  icon: Icons.calendar_month,
                ),
                
                // Tab 3: Past appointments
                _buildSimpleAppointmentsList(
                  isToday: false,
                  isUpcoming: false,
                  isPast: true,
                  emptyMessage: 'No tienes historial de citas',
                  icon: Icons.history,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Opcionalmente navegar a una pantalla para crear citas manualmente
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Esta funcionalidad está en desarrollo'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Crear nueva cita',
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget _buildAppointmentsList({
    required List<List<dynamic>> where,
    required List<dynamic> orderBy,
    required String emptyMessage,
    bool isUpcoming = false,
    bool isToday = false,
    bool isPast = false,
  }) {
    // Build query
    Query query = FirebaseFirestore.instance.collection('appointments');
    
    // Apply basic filters
    for (var condition in where) {
      if (condition.length >= 3) {
        String field = condition[0];
        String operator = condition[1];
        dynamic value = condition[2];
        
        // Handle different operators
        switch (operator) {
          case '==':
            query = query.where(field, isEqualTo: value);
            break;
          case 'in':
            if (value is List) {
              query = query.where(field, whereIn: value);
            }
            break;
          case '>=':
            query = query.where(field, isGreaterThanOrEqualTo: value);
            break;
          case '<':
            query = query.where(field, isLessThan: value);
            break;
        }
      }
    }
    
    // Apply ordering
    query = query.orderBy(orderBy[0], descending: orderBy[1] as bool);
    
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
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
                Icon(
                  isUpcoming ? Icons.event_busy : (isToday ? Icons.today : Icons.history),
                  size: 56, 
                  color: Colors.grey
                ),
                SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final appointments = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index].data() as Map<String, dynamic>;
            final appointmentId = appointments[index].id;
            
            // Get date and time from the appointment
            final dateString = appointment['date'] as String? ?? '';
            DateTime dateTime;
               
            try {
              if (appointment['appointmentDateTime'] != null && appointment['appointmentDateTime'] is Timestamp) {
                dateTime = (appointment['appointmentDateTime'] as Timestamp).toDate();
              } else {
                dateTime = DateTime.parse(dateString);
              }
            } catch (e) {
              // Fallback date if parsing fails
              dateTime = DateTime.now();
              print('Error parsing date: $e');
            }
               
            // Format date and time
            String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(dateTime);
            formattedDate = formattedDate.substring(0, 1).toUpperCase() + formattedDate.substring(1);
            String formattedTime = DateFormat('HH:mm', 'es').format(dateTime);
            
            // Determine status color and text
            Color statusColor;
            String statusText;
            final status = appointment['status'] as String? ?? 'pending';
            
            switch (status.toLowerCase()) {
              case 'confirmed':
                statusColor = Colors.green;
                statusText = 'Confirmada';
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
            
            // Get patient ID for loading patient info
            final patientId = appointment['patientId'] as String? ?? '';
            
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with patient info and status
                  Container(
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: ListTile(
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
                      title: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('patients')
                            .doc(patientId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Cargando información...');
                          }
                                        
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Text('Paciente ID: $patientId');
                          }
                          
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final firstName = data?['firstName'] ?? '';
                          final lastName = data?['lastName'] ?? '';
                          
                          return Text(
                            '$firstName $lastName',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          );
                        },
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: statusColor, width: 1.5),
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
                  ),
                  
                  // Date and time info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, 
                                 color: Theme.of(context).primaryColor, 
                                 size: 20),
                            SizedBox(width: 12),
                            Text(
                              formattedDate,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, 
                                 color: Theme.of(context).primaryColor, 
                                 size: 20),
                            SizedBox(width: 12),
                            Text(
                              "Hora: $formattedTime",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        
                        // Show notes if available
                        if (appointment['details'] != null && appointment['details'].toString().isNotEmpty) ...[
                          SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes, 
                                  color: Theme.of(context).primaryColor,
                                  size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  appointment['details'].toString(),
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  Divider(height: 1),
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Show medical history button
                        OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to patient's medical records
                            context.goPatientMedicalRecords(patientId);
                          },
                          icon: Icon(Icons.medical_services_outlined),
                          label: Text('Historial'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(width: 8),
                        
                        // Different actions based on appointment status
                        if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed') ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAppointmentActions(context, appointmentId, status, dateTime);
                            },
                            icon: Icon(Icons.more_horiz),
                            label: Text('Opciones'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ] else if (status.toLowerCase() == 'completed') ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              // Show appointment details or notes
                              _showAppointmentDetails(context, appointment, patientId);
                            },
                            icon: Icon(Icons.visibility),
                            label: Text('Ver detalles'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
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
  
  // Show appointment actions dialog
  void _showAppointmentActions(BuildContext context, String appointmentId, String status, DateTime appointmentDateTime) {
    final bool isPast = appointmentDateTime.isBefore(DateTime.now());
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Opciones de cita'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(appointmentDateTime)),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Divider(),
              
              // Different options based on appointment status and date
              if (!isPast && status.toLowerCase() != 'cancelled') ...[
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Confirmar cita'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateAppointmentStatus(appointmentId, 'confirmed');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Cancelar cita'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmCancellation(context, appointmentId);
                  },
                ),
              ],
              
              if (isPast && status.toLowerCase() != 'completed' && status.toLowerCase() != 'cancelled') ...[
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.blue),
                  title: Text('Marcar como completada'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateAppointmentStatus(appointmentId, 'completed');
                  },
                ),
              ],
              
              // These options are always available
              ListTile(
                leading: Icon(Icons.chat_bubble_outline),
                title: Text('Añadir notas'),
                onTap: () {
                  Navigator.pop(context);
                  _addAppointmentNotes(context, appointmentId);
                },
              ),
              
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Contactar paciente'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement contact patient functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Funcionalidad en desarrollo')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Confirm cancellation dialog
  void _confirmCancellation(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar Cita'),
        content: Text('¿Estás seguro que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointmentId, 'cancelled');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
  
  // Update appointment status
  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      setState(() {
        isLoading = true;
      });
      
      await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed' 
                ? 'Cita confirmada exitosamente' 
                : status == 'cancelled'
                    ? 'Cita cancelada exitosamente'
                    : 'Estado de cita actualizado'
          ),
          backgroundColor: 
              status == 'confirmed' 
                  ? Colors.green 
                  : status == 'cancelled'
                      ? Colors.red
                      : Colors.blue,
        ),
      );
    } catch (e) {
      print('Error updating appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la cita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Add notes to appointment
  void _addAppointmentNotes(BuildContext context, String appointmentId) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir Notas'),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            hintText: 'Escribe tus notas sobre la cita aquí...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              if (notesController.text.trim().isEmpty) return;
                   
              try {
                await FirebaseFirestore.instance
                  .collection('appointments')
                  .doc(appointmentId)
                  .update({
                    'details': notesController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notas guardadas correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar notas: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  // Show appointment details
  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> appointment, String patientId) {
    final dateString = appointment['date'] as String? ?? '';
    DateTime dateTime;
    
    try {
      if (appointment['appointmentDateTime'] != null && appointment['appointmentDateTime'] is Timestamp) {
        dateTime = (appointment['appointmentDateTime'] as Timestamp).toDate();
      } else {
        dateTime = DateTime.parse(dateString);
      }
    } catch (e) {
      dateTime = DateTime.now();
    }
    
    final formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
    final formattedTime = DateFormat('HH:mm').format(dateTime);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de la Cita'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(patientId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Cargando información del paciente...');
                  }
                  
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Text('Paciente ID: $patientId');
                  }
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final firstName = data?['firstName'] ?? '';
                  final lastName = data?['lastName'] ?? '';
                  final email = data?['email'] ?? '';
                  final phoneN = data?['phoneN'] ?? '';
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Paciente:', '$firstName $lastName'),
                      if (email.isNotEmpty) _buildDetailRow('Email:', email),
                      if (phoneN.isNotEmpty) _buildDetailRow('Teléfono:', phoneN),
                    ],
                  );
                },
              ),
              
              Divider(),
              _buildDetailRow('Fecha:', formattedDate),
              _buildDetailRow('Hora:', formattedTime),
              _buildDetailRow('Estado:', appointment['status'] ?? 'Pendiente'),
              
              if (appointment['details'] != null && appointment['details'].toString().isNotEmpty) ...[
                Divider(),
                Text(
                  'Notas:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(appointment['details'].toString()),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.goPatientMedicalRecords(patientId);
            },
            child: Text('Ver Historial Médico'),
          ),
        ],
      ),
    );
  }
  
  // Helper to build detail rows in appointment details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Añade este nuevo método a tu clase

  Widget _buildSimpleAppointmentsList({
    required bool isToday,
    required bool isUpcoming,
    required bool isPast,
    required String emptyMessage,
    required IconData icon,
  }) {
    print('Construyendo lista de citas: isToday=$isToday, isUpcoming=$isUpcoming, isPast=$isPast');

    // Consulta simple: solo buscar por doctorId
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: currentDoctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('Error en consulta: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Error al cargar las citas: ${snapshot.error}'),
                SizedBox(height: 8),
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
                Icon(icon, size: 56, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        // Obtener la fecha actual
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(Duration(days: 1));
        
        // Filtrar las citas según la pestaña
        final filteredAppointments = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Extraer la fecha de la cita
          DateTime? appointmentDate;
          if (data['appointmentDateTime'] != null && data['appointmentDateTime'] is Timestamp) {
            appointmentDate = (data['appointmentDateTime'] as Timestamp).toDate();
          } else if (data['date'] != null && data['date'] is String) {
            try {
              appointmentDate = DateTime.parse(data['date']);
            } catch (e) {
              print('Error al convertir fecha: $e');
              return false;
            }
          } else {
            print('Formato de fecha no reconocido en la cita ${doc.id}');
            return false;
          }
          
          if (appointmentDate == null) return false;
          
          final appointmentDay = DateTime(
            appointmentDate.year, 
            appointmentDate.month, 
            appointmentDate.day
          );
          
          final status = (data['status'] as String?)?.toLowerCase() ?? 'pending';
          
          // Filtrar según la pestaña
          if (isToday) {
            // Citas de hoy (independientemente del estado)
            return appointmentDay.isAtSameMomentAs(today) && 
                   status != 'cancelled'; // Excluir canceladas
          } 
          else if (isUpcoming) {
            // Citas futuras (excluyendo hoy)
            return appointmentDay.isAfter(today) && 
                   status != 'cancelled' && 
                   status != 'completed';
          } 
          else if (isPast) {
            // Citas pasadas o completadas/canceladas
            return appointmentDay.isBefore(today) || 
                   status == 'completed' || 
                   status == 'cancelled';
          }
          
          return false;
        }).toList();
        
        // Ordenar las citas
        filteredAppointments.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          
          DateTime? dateA, dateB;
          
          if (dataA['appointmentDateTime'] is Timestamp) {
            dateA = (dataA['appointmentDateTime'] as Timestamp).toDate();
          } else if (dataA['date'] is String) {
            try {
              dateA = DateTime.parse(dataA['date']);
            } catch (e) {
              print('Error parsing date A: $e');
            }
          }
          
          if (dataB['appointmentDateTime'] is Timestamp) {
            dateB = (dataB['appointmentDateTime'] as Timestamp).toDate();
          } else if (dataB['date'] is String) {
            try {
              dateB = DateTime.parse(dataB['date']);
            } catch (e) {
              print('Error parsing date B: $e');
            }
          }
          
          if (dateA == null || dateB == null) return 0;
          
          // Para historial, mostrar las más recientes primero
          return isPast ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
        });
        
        if (filteredAppointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 56, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        // Mostrar títulos de sección para las citas futuras (agrupar por fecha)
        if (isUpcoming) {
          final appointmentsByDate = <String, List<QueryDocumentSnapshot>>{};
          
          for (final doc in filteredAppointments) {
            final data = doc.data() as Map<String, dynamic>;
            DateTime? appointmentDate;
            
            if (data['appointmentDateTime'] != null && data['appointmentDateTime'] is Timestamp) {
              appointmentDate = (data['appointmentDateTime'] as Timestamp).toDate();
            } else if (data['date'] != null && data['date'] is String) {
              try {
                appointmentDate = DateTime.parse(data['date']);
              } catch (e) {
                continue;
              }
            }
            
            if (appointmentDate == null) continue;
            
            final dateKey = DateFormat('yyyy-MM-dd').format(appointmentDate);
            if (!appointmentsByDate.containsKey(dateKey)) {
              appointmentsByDate[dateKey] = [];
            }
            
            appointmentsByDate[dateKey]!.add(doc);
          }
          
          // Crear una lista con separadores de fecha
          final sortedDates = appointmentsByDate.keys.toList()..sort();
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length * 2, // Duplicamos para incluir headers
            itemBuilder: (context, index) {
              // Headers para las fechas (posiciones pares)
              if (index.isEven) {
                final dateKey = sortedDates[index ~/ 2];
                final DateTime date = DateTime.parse(dateKey);
                final String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(date);
                final String capitalizedDate = formattedDate.substring(0, 1).toUpperCase() + formattedDate.substring(1);
                
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event, 
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          capitalizedDate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Citas para la fecha (posiciones impares)
              final dateKey = sortedDates[(index - 1) ~/ 2];
              final appointments = appointmentsByDate[dateKey]!;
              
              return Column(
                children: appointments.map((doc) {
                  final appointment = doc.data() as Map<String, dynamic>;
                  final appointmentId = doc.id;
                  
                  // Aquí vas a reutilizar tu código para construir cada elemento de cita
                  return _buildAppointmentItem(appointment, appointmentId);
                }).toList(),
              );
            },
          );
        }
        
        // Para las otras pestañas, mostrar lista simple
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final appointment = filteredAppointments[index].data() as Map<String, dynamic>;
            final appointmentId = filteredAppointments[index].id;
            
            return _buildAppointmentItem(appointment, appointmentId);
          },
        );
      },
    );
  }

  // Método auxiliar para construir cada elemento de cita
  Widget _buildAppointmentItem(Map<String, dynamic> appointment, String appointmentId) {
    // Get date and time from the appointment
    final dateString = appointment['date'] as String? ?? '';
    DateTime dateTime;
       
    try {
      if (appointment['appointmentDateTime'] != null && appointment['appointmentDateTime'] is Timestamp) {
        dateTime = (appointment['appointmentDateTime'] as Timestamp).toDate();
      } else {
        dateTime = DateTime.parse(dateString);
      }
    } catch (e) {
      // Fallback date if parsing fails
      dateTime = DateTime.now();
      print('Error parsing date: $e');
    }
       
    // Format date and time
    String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(dateTime);
    formattedDate = formattedDate.substring(0, 1).toUpperCase() + formattedDate.substring(1);
    String formattedTime = DateFormat('HH:mm', 'es').format(dateTime);
    
    // Determine status color and text
    Color statusColor;
    String statusText;
    final status = appointment['status'] as String? ?? 'pending';
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'Confirmada';
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
    
    // Get patient ID for loading patient info
    final patientId = appointment['patientId'] as String? ?? '';
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with patient info and status
          Container(
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: ListTile(
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
              title: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(patientId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Cargando información...');
                  }
                                
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Text('Paciente ID: $patientId');
                  }
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final firstName = data?['firstName'] ?? '';
                  final lastName = data?['lastName'] ?? '';
                  
                  return Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  );
                },
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor, width: 1.5),
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
          ),
          
          // Rest of the appointment item - same as your existing code
          // Copiar el resto de tu código de appointment item aquí
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, 
                         color: Theme.of(context).primaryColor, 
                         size: 20),
                    SizedBox(width: 12),
                    Text(
                      formattedDate,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, 
                         color: Theme.of(context).primaryColor, 
                         size: 20),
                    SizedBox(width: 12),
                    Text(
                      "Hora: $formattedTime",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                
                // Show notes if available
                if (appointment['details'] != null && appointment['details'].toString().isNotEmpty) ...[
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, 
                          color: Theme.of(context).primaryColor,
                          size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appointment['details'].toString(),
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          Divider(height: 1),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Show medical history button
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to patient's medical records
                    context.goPatientMedicalRecords(patientId);
                  },
                  icon: Icon(Icons.medical_services_outlined),
                  label: Text('Historial'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(width: 8),
                
                // Different actions based on appointment status
                if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed') ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAppointmentActions(context, appointmentId, status, dateTime);
                    },
                    icon: Icon(Icons.more_horiz),
                    label: Text('Opciones'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (status.toLowerCase() == 'completed') ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      // Show appointment details or notes
                      _showAppointmentDetails(context, appointment, patientId);
                    },
                    icon: Icon(Icons.visibility),
                    label: Text('Ver detalles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}