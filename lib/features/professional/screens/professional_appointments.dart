// lib/features/professional/screens/professional_appointments.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '/navigation/shared_drawer.dart';
import '/navigation/router.dart';
import '/core/widgets/responsive_widget.dart';
import '/core/services/error_logger.dart';
import '/features/appointments/services/appointment_service.dart';
import '/features/appointments/models/appointment.dart';
import '/features/auth/providers/session_provider.dart';

/// Professional appointments screen
/// Allows professionals to view and manage their upcoming and past appointments
class ProfessionalAppointments extends HookConsumerWidget {
  final VoidCallback toggleTheme;
  
  const ProfessionalAppointments({
    Key? key,
    required this.toggleTheme,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentService = ref.watch(appointmentServiceProvider);
    final userId = ref.watch(userIdProvider);
    
    // Track current filter and view
    final selectedFilter = useState<String>('upcoming');
    final isGridView = useState<bool>(false);
    final searchQuery = useState<String>('');
    
    // Date range filter state
    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);
    
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Citas'),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: toggleTheme,
            ),
          ],
        ),
        drawer: SharedDrawer(),
        body: const Center(
          child: Text('Debes iniciar sesión para ver tus citas'),
        ),
      );
    }
    
    // Show filter sheet
    void showFilterSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtrar Citas',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Estado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Todas'),
                          selected: selectedFilter.value == 'all',
                          onSelected: (selected) {
                            if (selected) {
                              selectedFilter.value = 'all';
                              Navigator.pop(context);
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('Próximas'),
                          selected: selectedFilter.value == 'upcoming',
                          onSelected: (selected) {
                            if (selected) {
                              selectedFilter.value = 'upcoming';
                              Navigator.pop(context);
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('Hoy'),
                          selected: selectedFilter.value == 'today',
                          onSelected: (selected) {
                            if (selected) {
                              selectedFilter.value = 'today';
                              Navigator.pop(context);
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('Pasadas'),
                          selected: selectedFilter.value == 'past',
                          onSelected: (selected) {
                            if (selected) {
                              selectedFilter.value = 'past';
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date range selection
                    Text(
                      'Rango de Fechas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: startDate.value ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  startDate.value = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                startDate.value == null 
                                    ? 'Fecha inicial' 
                                    : DateFormat('dd/MM/yyyy').format(startDate.value!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: endDate.value ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  endDate.value = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                endDate.value == null 
                                    ? 'Fecha final' 
                                    : DateFormat('dd/MM/yyyy').format(endDate.value!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Display options
                    Text(
                      'Opciones de Visualización',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Vista de cuadrícula'),
                      value: isGridView.value,
                      onChanged: (value) {
                        setState(() {
                          isGridView.value = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Apply & Reset buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                startDate.value = null;
                                endDate.value = null;
                                isGridView.value = false;
                                selectedFilter.value = 'upcoming';
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Restablecer'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Aplicar Filtros'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Citas'),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: showFilterSheet,
            tooltip: 'Filtrar',
          ),
          // Toggle view mode
          IconButton(
            icon: Icon(isGridView.value ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              isGridView.value = !isGridView.value;
            },
            tooltip: isGridView.value ? 'Vista de lista' : 'Vista de cuadrícula',
          ),
          // Theme toggle
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: toggleTheme,
          ),
        ],
      ),
      drawer: SharedDrawer(),
      body: Column(
        children: [
          // Filter chips and search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Citas', 
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                // Search field
                TextField(
                  onChanged: (value) {
                    searchQuery.value = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por paciente...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todas'),
                        selected: selectedFilter.value == 'all',
                        onSelected: (selected) {
                          if (selected) selectedFilter.value = 'all';
                        },
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Próximas'),
                        selected: selectedFilter.value == 'upcoming',
                        onSelected: (selected) {
                          if (selected) selectedFilter.value = 'upcoming';
                        },
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Hoy'),
                        selected: selectedFilter.value == 'today',
                        onSelected: (selected) {
                          if (selected) selectedFilter.value == 'today';
                        },
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pasadas'),
                        selected: selectedFilter.value == 'past',
                        onSelected: (selected) {
                          if (selected) selectedFilter.value == 'past';
                        },
                        showCheckmark: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Appointment list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: appointmentService.getAppointmentsByProfessional(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (snapshot.hasError) {
                  ErrorLogger.logError(
                    'Error loading professional appointments',
                    snapshot.error!,
                    StackTrace.current,
                  );
                  
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error al cargar las citas: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Force refresh by rebuilding the widget
                            (context as Element).markNeedsBuild();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedFilter.value == 'upcoming'
                              ? Icons.calendar_month_outlined
                              : Icons.history_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedFilter.value == 'upcoming'
                              ? 'No tienes citas próximas'
                              : selectedFilter.value == 'today'
                                  ? 'No tienes citas para hoy'
                                  : 'No tienes citas pasadas',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }
                
                // Convert to appointment objects
                final appointments = snapshot.data!.docs.map((doc) {
                  return Appointment.fromFirestore(doc);
                }).toList();
                
                // Apply search filter
                final filteredBySearch = searchQuery.value.isEmpty 
                  ? appointments 
                  : appointments.where((apt) {
                      // This is a placeholder, in production you'd need to fetch patient names
                      return apt.patientId.toLowerCase().contains(searchQuery.value.toLowerCase());
                    }).toList();
                
                // Filter appointments
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final tomorrow = today.add(const Duration(days: 1));
                
                List<Appointment> filteredAppointments;
                
                switch (selectedFilter.value) {
                  case 'upcoming':
                    filteredAppointments = filteredBySearch.where((apt) {
                      final aptDate = DateTime.parse(apt.date);
                      return aptDate.isAfter(now);
                    }).toList();
                    break;
                  case 'today':
                    filteredAppointments = filteredBySearch.where((apt) {
                      final aptDate = DateTime.parse(apt.date);
                      return aptDate.isAfter(today) && aptDate.isBefore(tomorrow);
                    }).toList();
                    break;
                  case 'past':
                    filteredAppointments = filteredBySearch.where((apt) {
                      final aptDate = DateTime.parse(apt.date);
                      return aptDate.isBefore(now);
                    }).toList();
                    break;
                  default:
                    filteredAppointments = filteredBySearch;
                }
                
                // Apply date range filter if set
                if (startDate.value != null) {
                  filteredAppointments = filteredAppointments.where((apt) {
                    final aptDate = DateTime.parse(apt.date);
                    return aptDate.isAfter(startDate.value!) || 
                           aptDate.isAtSameMomentAs(startDate.value!);
                  }).toList();
                }
                
                if (endDate.value != null) {
                  filteredAppointments = filteredAppointments.where((apt) {
                    final aptDate = DateTime.parse(apt.date);
                    return aptDate.isBefore(endDate.value!.add(const Duration(days: 1)));
                  }).toList();
                }
                
                // Sort appointments
                filteredAppointments.sort((a, b) {
                  final dateA = DateTime.parse(a.date);
                  final dateB = DateTime.parse(b.date);
                  return selectedFilter.value == 'past'
                      ? dateB.compareTo(dateA) // Most recent first for past
                      : dateA.compareTo(dateB); // Soonest first for upcoming
                });
                
                if (filteredAppointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedFilter.value == 'upcoming'
                              ? Icons.calendar_month_outlined
                              : Icons.history_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedFilter.value == 'upcoming'
                              ? 'No tienes citas próximas'
                              : selectedFilter.value == 'today'
                                  ? 'No tienes citas para hoy'
                                  : 'No tienes citas pasadas',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }
                
                // Build the appointments view based on selected view mode and screen size
                return ResponsiveBuilder(
                  builder: (context, layoutSize) {
                    if (isGridView.value) {
                      return _buildAppointmentsGrid(
                        context,
                        ref,
                        filteredAppointments,
                        layoutSize,
                      );
                    } else {
                      return _buildAppointmentsList(
                        context,
                        ref,
                        filteredAppointments,
                        layoutSize,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build grid view of appointments
  Widget _buildAppointmentsGrid(
    BuildContext context,
    WidgetRef ref,
    List<Appointment> appointments,
    LayoutSize layoutSize,
  ) {
    // Determine number of columns based on layout size
    int crossAxisCount;
    
    switch (layoutSize) {
      case LayoutSize.mobile:
        crossAxisCount = 1;
        break;
      case LayoutSize.tablet:
        crossAxisCount = 2;
        break;
      case LayoutSize.desktop:
        crossAxisCount = 3;
        break;
      case LayoutSize.largeDesktop:
        crossAxisCount = 4;
        break;
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(context, ref, appointment);
      },
    );
  }
  
  /// Build list view of appointments
  Widget _buildAppointmentsList(
    BuildContext context,
    WidgetRef ref,
    List<Appointment> appointments,
    LayoutSize layoutSize,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header row
            if (layoutSize != LayoutSize.mobile) _buildListHeader(context),
            
            // Appointments list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: appointments.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return _buildAppointmentListItem(
                    context,
                    ref,
                    appointment,
                    layoutSize,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build header row for list view
  Widget _buildListHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Paciente',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Fecha y Hora',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Estado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Detalles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 100), // Space for actions
        ],
      ),
    );
  }
  
  /// Build list item for an appointment
  Widget _buildAppointmentListItem(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
    LayoutSize layoutSize,
  ) {
    final appointmentDate = DateTime.parse(appointment.date);
    final formattedDate = DateFormat('dd/MM/yyyy').format(appointmentDate);
    final formattedTime = DateFormat('HH:mm').format(appointmentDate);
    
    // For mobile layout
    if (layoutSize == LayoutSize.mobile) {
      return ListTile(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('patients')
              .doc(appointment.patientId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando información del paciente...');
            }
            
            if (!snapshot.hasData || snapshot.data == null) {
              return Text('Paciente ID: ${appointment.patientId}');
            }
            
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final name = data?['firstName'] ?? '';
            final lastName = data?['lastName'] ?? '';
            
            return Text('$name $lastName');
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$formattedDate $formattedTime'),
            Text(appointment.details ?? 'Sin detalles'),
          ],
        ),
        trailing: _buildStatusChip(appointment.status),
        onTap: () => _showAppointmentDetails(context, ref, appointment),
      );
    }
    
    // For larger screens
    return InkWell(
      onTap: () => _showAppointmentDetails(context, ref, appointment),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Patient name
            Expanded(
              flex: 2,
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(appointment.patientId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Cargando...');
                  }
                  
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Text('Paciente ID: ${appointment.patientId}');
                  }
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final name = data?['firstName'] ?? '';
                  final lastName = data?['lastName'] ?? '';
                  
                  return Text('$name $lastName');
                },
              ),
            ),
            
            // Date and time
            Expanded(
              flex: 2,
              child: Text('$formattedDate $formattedTime'),
            ),
            
            // Status
            Expanded(
              flex: 1,
              child: _buildStatusChip(appointment.status),
            ),
            
            // Details
            Expanded(
              flex: 2,
              child: Text(
                appointment.details ?? 'Sin detalles',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Actions
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.medical_services_outlined),
                    tooltip: 'Historial Médico',
                    onPressed: () {
                      // Navigate to patient medical records
                      context.goPatientMedicalRecords(appointment.patientId);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Más opciones',
                    onPressed: () => _showAppointmentActionMenu(
                      context,
                      ref,
                      appointment,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build card for an appointment
  Widget _buildAppointmentCard(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
  ) {
    final appointmentDate = DateTime.parse(appointment.date);
    final formattedDate = DateFormat('dd/MM/yyyy').format(appointmentDate);
    final formattedTime = DateFormat('HH:mm').format(appointmentDate);
    final now = DateTime.now();
    final isPast = appointmentDate.isBefore(now);
    
    // Color based on status
    Color cardColor = Colors.white;
    Color borderColor;
    
    switch (appointment.status.toLowerCase()) {
      case 'confirmed':
        borderColor = Colors.green;
        break;
      case 'cancelled':
        borderColor = Colors.red;
        break;
      case 'completed':
        borderColor = Colors.blue;
        break;
      default:
        borderColor = Colors.orange;
    }
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: () => _showAppointmentDetails(context, ref, appointment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and time header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Patient name
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(appointment.patientId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Cargando información del paciente...');
                  }
                  
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Text('Paciente ID: ${appointment.patientId}');
                  }
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final name = data?['firstName'] ?? '';
                  final lastName = data?['lastName'] ?? '';
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paciente:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '$name $lastName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 8), 
            
              
              if (appointment.details != null && appointment.details!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Detalles:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  appointment.details!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Bottom row with status and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(appointment.status),
                  
                  // Actions menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Opciones',
                    onSelected: (action) {
                      _handleAppointmentAction(context, ref, appointment, action);
                    },
                    itemBuilder: (context) => [
                      if (!isPast && appointment.status.toLowerCase() != 'cancelled')
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_outlined, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Cancelar'),
                            ],
                          ),
                        ),
                      
                      if (!isPast && appointment.status.toLowerCase() == 'pending')
                        const PopupMenuItem(
                          value: 'confirm',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Confirmar'),
                            ],
                          ),
                        ),
                      
                      if (isPast && appointment.status.toLowerCase() != 'completed' && 
                          appointment.status.toLowerCase() != 'cancelled')
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.task_alt, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Marcar completada'),
                            ],
                          ),
                        ),
                      
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text('Ver detalles'),
                          ],
                        ),
                      ),
                      
                      const PopupMenuItem(
                        value: 'medical_records',
                        child: Row(
                          children: [
                            Icon(Icons.medical_services_outlined),
                            SizedBox(width: 8),
                            Text('Historial médico'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build status chip with appropriate color
  Widget _buildStatusChip(String status) {
    late Color chipColor;
    late String statusText;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        chipColor = Colors.green;
        statusText = 'Confirmada';
        break;
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Pendiente';
        break;
      case 'cancelled':
        chipColor = Colors.red;
        statusText = 'Cancelada';
        break;
      case 'completed':
        chipColor = Colors.blue;
        statusText = 'Completada';
        break;
      default:
        chipColor = Colors.grey;
        statusText = status;
    }
    
    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  /// Show appointment details dialog
  void _showAppointmentDetails(
    BuildContext context, 
    WidgetRef ref, 
    Appointment appointment
  ) {
    final appointmentDate = DateTime.parse(appointment.date);
    final formattedDate = DateFormat('dd/MM/yyyy').format(appointmentDate);
    final formattedTime = DateFormat('HH:mm').format(appointmentDate);
    final appointmentService = ref.read(appointmentServiceProvider);
    final now = DateTime.now();
    final isPast = appointmentDate.isBefore(now);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalles de la Cita'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Patient info
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('patients')
                      .doc(appointment.patientId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Cargando información del paciente...');
                    }
                    
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Text('Paciente ID: ${appointment.patientId}');
                    }
                    
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final name = data?['firstName'] ?? '';
                    final lastName = data?['lastName'] ?? '';
                    final email = data?['email'] ?? '';
                    final phone = data?['phoneN'] ?? '';
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Paciente:', '$name $lastName'),
                        if (email.isNotEmpty)
                          _buildDetailRow('Email:', email),
                        if (phone.isNotEmpty)
                          _buildDetailRow('Teléfono:', phone),
                      ],
                    );
                  },
                ),
                
                const Divider(),
                
                // Appointment details
                _buildDetailRow('Fecha:', formattedDate),
                _buildDetailRow('Hora:', formattedTime),
                _buildDetailRow('Estado:', appointment.status),          

              ],
            ),
          ),
          actions: [
            // Action buttons
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            
            if (!isPast && appointment.status.toLowerCase() != 'cancelled')
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancelar Cita'),
                      content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sí'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm ?? false) {
                    try {
                      await appointmentService.updateAppointmentStatus(
                        appointment.id,
                        'cancelled',
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cita cancelada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al cancelar la cita: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Cancelar Cita'),
              ),
            
            if (isPast && appointment.status.toLowerCase() != 'completed' &&
                appointment.status.toLowerCase() != 'cancelled')
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await appointmentService.updateAppointmentStatus(
                      appointment.id,
                      'completed',
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cita marcada como completada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar la cita: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
                child: const Text('Marcar Completada'),
              ),
          ],
        );
      },
    );
  }
  
  /// Build a detail row for appointment details dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Show appointment action menu
  void _showAppointmentActionMenu(
    BuildContext context, 
    WidgetRef ref, 
    Appointment appointment
  ) {
    final appointmentDate = DateTime.parse(appointment.date);
    final now = DateTime.now();
    final isPast = appointmentDate.isBefore(now);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ver detalles'),
                leading: const Icon(Icons.info_outline),
                onTap: () {
                  Navigator.pop(context);
                  _showAppointmentDetails(context, ref, appointment);
                },
              ),
              
              if (!isPast && appointment.status.toLowerCase() != 'cancelled')
                ListTile(
                  title: const Text('Cancelar cita'),
                  leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onTap: () {
                    Navigator.pop(context);
                    _handleAppointmentAction(context, ref, appointment, 'cancel');
                  },
                ),
              
              if (!isPast && appointment.status.toLowerCase() == 'pending')
                ListTile(
                  title: const Text('Confirmar cita'),
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onTap: () {
                    Navigator.pop(context);
                    _handleAppointmentAction(context, ref, appointment, 'confirm');
                  },
                ),
              
              if (isPast && appointment.status.toLowerCase() != 'completed' && 
                  appointment.status.toLowerCase() != 'cancelled')
                ListTile(
                  title: const Text('Marcar como completada'),
                  leading: const Icon(Icons.task_alt, color: Colors.blue),
                  onTap: () {
                    Navigator.pop(context);
                    _handleAppointmentAction(context, ref, appointment, 'complete');
                  },
                ),
              
              ListTile(
                title: const Text('Ver historial médico'),
                leading: const Icon(Icons.medical_services_outlined),
                onTap: () {
                  Navigator.pop(context);
                  _handleAppointmentAction(context, ref, appointment, 'medical_records');
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Handle appointment actions
  void _handleAppointmentAction(
    BuildContext context, 
    WidgetRef ref, 
    Appointment appointment, 
    String action
  ) async {
    final appointmentService = ref.read(appointmentServiceProvider);
    
    switch (action) {
      case 'details':
        _showAppointmentDetails(context, ref, appointment);
        break;
        
      case 'cancel':
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancelar Cita'),
            content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí'),
              ),
            ],
          ),
        );
        
        if (confirm ?? false) {
          try {
            await appointmentService.updateAppointmentStatus(
              appointment.id,
              'cancelled',
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cita cancelada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cancelar la cita: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
        
      case 'confirm':
        try {
          await appointmentService.updateAppointmentStatus(
            appointment.id,
            'confirmed',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita confirmada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al confirmar la cita: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
        
      case 'complete':
        try {
          await appointmentService.updateAppointmentStatus(
            appointment.id,
            'completed',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita marcada como completada'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar la cita: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
        
      case 'medical_records':
        // Navigate to patient medical records
        context.goPatientMedicalRecords(appointment.patientId);
        break;
    }
  }
}