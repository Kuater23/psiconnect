// lib/features/professional/providers/professional_providers.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/core/services/web_firestore_service.dart';
import '/core/exceptions/app_exception.dart';
import '/core/services/error_logger.dart';
import '/features/appointments/models/appointment.dart';
import '/features/auth/providers/session_provider.dart';

/// Provider for professional state
final professionalProvider = StateNotifierProvider<ProfessionalNotifier, ProfessionalState>((ref) {
  return ProfessionalNotifier(WebFirestoreService());
});

/// Provider for professional availability
final professionalAvailabilityProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, professionalId) async {
  try {
    final firestoreService = WebFirestoreService();
    final doc = await firestoreService.getDocument('professionals', professionalId);
    
    if (doc == null || !doc.exists) {
      return [];
    }
    
    final data = doc.data() as Map<String, dynamic>;
    final availability = data['availability'] as Map<String, dynamic>? ?? {};
    
    final List<String> days = List<String>.from(availability['days'] ?? []);
    final String startTime = availability['start_time'] ?? '09:00';
    final String endTime = availability['end_time'] ?? '17:00';
    
    // Generate time slots for each available day
    final List<Map<String, dynamic>> availableSlots = [];
    
    for (final day in days) {
      availableSlots.add({
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
      });
    }
    
    return availableSlots;
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching professional availability', e, stackTrace);
    return [];
  }
});

/// Provider for professional's upcoming appointments
final professionalUpcomingAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  final session = ref.watch(sessionProvider);
  final userId = ref.watch(userIdProvider);
  
  if (session == null || session.role != 'professional' || userId == null) {
    return Stream.value([]);
  }
  
  final now = DateTime.now();
  
  try {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('professional_id', isEqualTo: userId)
        .where('date', isGreaterThan: now.toIso8601String())
        .orderBy('date')
        .limit(10)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList()
        );
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching professional upcoming appointments', e, stackTrace);
    return Stream.value([]);
  }
});

/// Provider for professional's patient list
final professionalPatientsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final session = ref.watch(sessionProvider);
  final userId = ref.watch(userIdProvider);
  
  if (session == null || session.role != 'professional' || userId == null) {
    return Stream.value([]);
  }
  
  try {
    // Get all patients who have had appointments with this professional
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('professional_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          // Extract unique patient IDs
          final Set<String> patientIds = snapshot.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['patient_id'] as String)
              .toSet();
              
          // Fetch patient details
          final List<Map<String, dynamic>> patients = [];
          
          for (final patientId in patientIds) {
            final patientDoc = await FirebaseFirestore.instance
                .collection('patients')
                .doc(patientId)
                .get();
                
            if (patientDoc.exists) {
              final patientData = patientDoc.data() as Map<String, dynamic>;
              patients.add({
                'id': patientId,
                'name': patientData['firstName'] ?? '',
                'lastName': patientData['lastName'] ?? '',
                'email': patientData['email'] ?? '',
                'lastAppointment': _getLastAppointmentDate(snapshot.docs, patientId),
              });
            }
          }
          
          return patients;
        });
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching professional patients', e, stackTrace);
    return Stream.value([]);
  }
});

/// Provider for professional stats
final professionalStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final session = ref.watch(sessionProvider);
  final userId = ref.watch(userIdProvider);
  
  if (session == null || session.role != 'professional' || userId == null) {
    return {};
  }
  
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  
  try {
    // Get appointments for this month
    final monthlyAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('professional_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .get();
    
    // Get upcoming appointments
    final upcomingAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('professional_id', isEqualTo: userId)
        .where('date', isGreaterThan: now.toIso8601String())
        .get();
    
    // Calculate stats
    final int totalMonthlyAppointments = monthlyAppointments.docs.length;
    final int upcomingCount = upcomingAppointments.docs.length;
    
    // Count appointments by status
    int completedCount = 0;
    int cancelledCount = 0;
    
    for (final doc in monthlyAppointments.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      
      if (status == 'completed') completedCount++;
      if (status == 'cancelled') cancelledCount++;
    }
    
    return {
      'totalMonthlyAppointments': totalMonthlyAppointments,
      'upcomingAppointments': upcomingCount,
      'completedAppointments': completedCount,
      'cancelledAppointments': cancelledCount,
      'monthName': _getMonthName(now.month),
    };
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching professional stats', e, stackTrace);
    return {};
  }
});

/// Provider for professional account completion status
final professionalProfileCompletionProvider = Provider.autoDispose<double>((ref) {
  final professionalState = ref.watch(professionalProvider);
  
  // Calculate completion percentage based on filled fields
  int totalFields = 8; // Total number of important profile fields
  int filledFields = 0;
  
  if (professionalState.name?.isNotEmpty ?? false) filledFields++;
  if (professionalState.lastName?.isNotEmpty ?? false) filledFields++;
  if (professionalState.address?.isNotEmpty ?? false) filledFields++;
  if (professionalState.phone?.isNotEmpty ?? false) filledFields++;
  if (professionalState.documentNumber?.isNotEmpty ?? false) filledFields++;
  if (professionalState.licenseNumber?.isNotEmpty ?? false) filledFields++;
  if (professionalState.selectedDays.isNotEmpty) filledFields++;
  if (professionalState.startTime != null && professionalState.endTime != null) filledFields++;
  
  return filledFields / totalFields;
});

/// Helper function to get the last appointment date for a patient
String _getLastAppointmentDate(List<QueryDocumentSnapshot> docs, String patientId) {
  final patientAppointments = docs
      .where((doc) => (doc.data() as Map<String, dynamic>)['patient_id'] == patientId)
      .toList();
      
  if (patientAppointments.isEmpty) return 'N/A';
  
  patientAppointments.sort((a, b) {
    final dateA = (a.data() as Map<String, dynamic>)['date'] as String;
    final dateB = (b.data() as Map<String, dynamic>)['date'] as String;
    return dateB.compareTo(dateA); // Sort in descending order
  });
  
  final lastAppointmentDate = (patientAppointments.first.data() as Map<String, dynamic>)['date'] as String;
  
  // Format the date
  try {
    final dateTime = DateTime.parse(lastAppointmentDate);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  } catch (e) {
    return lastAppointmentDate;
  }
}

/// Helper function to get month name
String _getMonthName(int month) {
  switch (month) {
    case 1: return 'Enero';
    case 2: return 'Febrero';
    case 3: return 'Marzo';
    case 4: return 'Abril';
    case 5: return 'Mayo';
    case 6: return 'Junio';
    case 7: return 'Julio';
    case 8: return 'Agosto';
    case 9: return 'Septiembre';
    case 10: return 'Octubre';
    case 11: return 'Noviembre';
    case 12: return 'Diciembre';
    default: return '';
  }
}

/// States for ProfessionalNotifier
class ProfessionalState {
  final String? uid;
  final String? name;
  final String? lastName;
  final String? address;
  final String? phone;
  final String? documentNumber;
  final String? documentType;
  final String? licenseNumber;
  final List<String> selectedDays;
  final String? startTime;
  final String? endTime;
  final bool isLoading;
  final bool hasData;
  final bool isEditing;

  ProfessionalState({
    this.uid,
    this.name,
    this.lastName,
    this.address,
    this.phone,
    this.documentNumber,
    this.documentType,
    this.licenseNumber,
    this.selectedDays = const [],
    this.startTime,
    this.endTime,
    this.isLoading = true,
    this.hasData = false,
    this.isEditing = false,
  });

  // Method to create a copy of the state with specific fields updated
  ProfessionalState copyWith({
    String? uid,
    String? name,
    String? lastName,
    String? address,
    String? phone,
    String? documentNumber,
    String? documentType,
    String? licenseNumber,
    List<String>? selectedDays,
    String? startTime,
    String? endTime,
    bool? isLoading,
    bool? hasData,
    bool? isEditing,
  }) {
    return ProfessionalState(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      documentNumber: documentNumber ?? this.documentNumber,
      documentType: documentType ?? this.documentType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      selectedDays: selectedDays ?? this.selectedDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isLoading: isLoading ?? this.isLoading,
      hasData: hasData ?? this.hasData,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

/// Notifier class for professional state
class ProfessionalNotifier extends StateNotifier<ProfessionalState> {
  final WebFirestoreService _firestoreService;

  ProfessionalNotifier(this._firestoreService)
      : super(ProfessionalState(isLoading: true)) {
    _loadUserData(); // Load professional data when initialized
  }

  /// Load professional data from Firestore
  Future<void> _loadUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      
      try {
        final doc = await _firestoreService.getDocument('doctors', uid);
        if (doc != null && doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Usar los nombres de campos correctos según tu esquema
          state = state.copyWith(
            uid: uid,
            name: data['firstName'] ?? '', // Cambiado de 'name' a 'firstName'
            lastName: data['lastName'] ?? '',
            address: data['address'] ?? '',
            phone: data['phoneN'] ?? '', // Cambiado de 'phone' a 'phoneN'
            documentNumber: data['dni'] ?? '', // Cambiado de 'documentNumber' a 'dni'
            licenseNumber: data['license']?.toString() ?? '', // Cambiado de 'n_matricula' a 'license'
            documentType: data['documentType'] ?? 'DNI',
            
            // Manejo correcto de disponibilidad
            selectedDays: List<String>.from(data['workDays'] ?? []), // Cambiado de 'availability'?['days'] a 'workDays'
            startTime: data['startTime'] ?? '09:00', // Cambiado de 'availability'?['start_time'] a 'startTime'
            endTime: data['endTime'] ?? '17:00', // Cambiado de 'availability'?['end_time'] a 'endTime'
            
            isLoading: false,
            hasData: true,
          );
        } else {
          state = state.copyWith(isLoading: false, hasData: false);
        }
      } catch (e, stackTrace) {
        ErrorLogger.logError('Error loading professional data', e, stackTrace);
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Save professional data to Firestore
  Future<void> saveUserData({
    required String name,
    required String lastName,
    required String address,
    required String phone,
    required String documentNumber,
    required String licenseNumber,
    required List<String> selectedDays,
    required String startTime,
    required String endTime,
  }) async {
    if (state.uid == null || state.uid!.isEmpty) return;
    
    try {
      state = state.copyWith(isLoading: true);
      
      await _firestoreService.updateDocument(
        'doctors',
        state.uid!,
        {
          'firstName': name, // Cambiado de 'name' a 'firstName'
          'lastName': lastName,
          'address': address,
          'phoneN': phone, // Cambiado de 'phone' a 'phoneN'
          'email': FirebaseAuth.instance.currentUser?.email,
          'dni': documentNumber, // Cambiado de 'documentNumber' a 'dni'
          'license': licenseNumber, // Cambiado de 'n_matricula' a 'license'
          'workDays': selectedDays, // Cambiado de structure anidada a campo directo
          'startTime': startTime, // Cambiado de estructura anidada a campo directo
          'endTime': endTime, // Cambiado de estructura anidada a campo directo
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      state = state.copyWith(
        name: name,
        lastName: lastName,
        address: address,
        phone: phone,
        documentNumber: documentNumber,
        licenseNumber: licenseNumber,
        selectedDays: selectedDays,
        startTime: startTime,
        endTime: endTime,
        isLoading: false,
        isEditing: false,
        hasData: true,
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error saving professional data', e, stackTrace);
      state = state.copyWith(isLoading: false);
      throw DataException('Error updating professional profile: ${e.toString()}');
    }
  }

  /// Toggle editing mode
  void setEditing(bool isEditing) {
    state = state.copyWith(isEditing: isEditing);
  }
  
  /// Reload professional data
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadUserData();
  }
}