import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/navigation/router.dart';
import 'package:Psiconnect/navigation/shared_drawer.dart';
import 'package:Psiconnect/core/widgets/responsive_widget.dart';
import 'package:intl/intl.dart';

class PatientFilesList extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  
  const PatientFilesList({
    Key? key,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  ConsumerState<PatientFilesList> createState() => _PatientFilesListState();
}

class _PatientFilesListState extends ConsumerState<PatientFilesList> {
  String? get currentDoctorId => FirebaseAuth.instance.currentUser?.uid;
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> patients = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Cargar la lista de pacientes del profesional actual
  Future<void> _loadPatients() async {
    if (currentDoctorId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Consultar todas las citas del profesional para obtener IDs de pacientes
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: currentDoctorId)
          .get();

      // Extraer IDs únicos de pacientes
      final Set<String> patientIds = appointmentsSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['patientId'] as String)
          .toSet();

      List<Map<String, dynamic>> patientsList = [];

      // Para cada paciente, obtener su información
      for (String patientId in patientIds) {
        final patientDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .get();

        if (patientDoc.exists) {
          final data = patientDoc.data()!;
          
          // Obtener la última cita con este paciente
          final lastAppointmentQuery = await FirebaseFirestore.instance
              .collection('appointments')
              .where('patientId', isEqualTo: patientId)
              .where('doctorId', isEqualTo: currentDoctorId)
              .orderBy('appointmentDateTime', descending: true)
              .limit(1)
              .get();
          
          String lastAppointment = 'Sin citas';
          if (lastAppointmentQuery.docs.isNotEmpty) {
            final lastAppointmentData = lastAppointmentQuery.docs.first.data();
            if (lastAppointmentData['appointmentDateTime'] != null) {
              final appointmentDate = (lastAppointmentData['appointmentDateTime'] as Timestamp).toDate();
              lastAppointment = DateFormat('dd/MM/yyyy').format(appointmentDate);
            }
          }
          
          patientsList.add({
            'id': patientId,
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'email': data['email'] ?? '',
            'phoneN': data['phoneN'] ?? '',
            'lastAppointment': lastAppointment,
          });
        }
      }

      setState(() {
        patients = patientsList;
        isLoading = false;
      });
    } catch (e) {
      print('Error cargando pacientes: $e');
      setState(() {
        errorMessage = 'Error al cargar la lista de pacientes: $e';
        isLoading = false;
      });
    }
  }

  // Filtrar pacientes por la búsqueda
  List<Map<String, dynamic>> get filteredPatients {
    if (searchQuery.isEmpty) return patients;
    
    return patients.where((patient) {
      final fullName = '${patient['firstName']} ${patient['lastName']}'.toLowerCase();
      final email = (patient['email'] ?? '').toLowerCase();
      return fullName.contains(searchQuery.toLowerCase()) || 
             email.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivos de Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: const SharedDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar paciente',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPatients,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : filteredPatients.isEmpty
                        ? const Center(
                          child: Text(
                            'No se encontraron pacientes',
                            style: TextStyle(fontSize: 16),
                          ),
                          )
                        : _buildPatientListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        return _buildPatientCard(filteredPatients[index]);
      },
    );
  }

  Widget _buildPatientGridView(int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        return _buildPatientCard(filteredPatients[index]);
      },
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navegar a la pantalla de historial médico del paciente
          context.goPatientMedicalRecords(
            patient['id'],
            patientName: '${patient['firstName']} ${patient['lastName']}',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    radius: 25,
                    child: Text(
                      patient['firstName'].isNotEmpty ? patient['firstName'][0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${patient['firstName']} ${patient['lastName']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (patient['email'] != null && patient['email'].isNotEmpty)
                          Text(
                            patient['email'],
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                patient['phoneN'] ?? 'Sin teléfono',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Última cita: ${patient['lastAppointment']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.goPatientMedicalRecords(
                        patient['id'],
                        patientName: '${patient['firstName']} ${patient['lastName']}',
                      );
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Ver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}