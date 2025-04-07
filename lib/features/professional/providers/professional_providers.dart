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
import 'package:Psiconnect/features/professional/models/professional_model.dart';

// Update the state to use ProfessionalModel
final professionalProvider = StateNotifierProvider<ProfessionalNotifier, AsyncValue<ProfessionalModel?>>((ref) {
  return ProfessionalNotifier(WebFirestoreService());
});

/// Provider for professional availability
final professionalAvailabilityProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, doctorId) async {
  try {
    final firestoreService = WebFirestoreService();
    final doc = await firestoreService.getDocument('professionals', doctorId);
    
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
        .where('doctorId', isEqualTo: userId)
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
        .where('doctorId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          // Extract unique patient IDs
          final Set<String> patientIds = snapshot.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['patientId'] as String)
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
        .where('doctorId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .get();
    
    // Get upcoming appointments
    final upcomingAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: userId)
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
  
  // Initialize with 0 for loading or error states
  if (professionalState is AsyncLoading) {
    return 0.0;
  }
  
  if (professionalState is AsyncError) {
    return 0.0;
  }
  
  // Get the actual professional model from the AsyncValue
  final professional = professionalState.value;
  
  // If no professional data, return 0
  if (professional == null) {
    return 0.0;
  }
  
  // Calculate completion percentage based on filled fields
  int totalFields = 8; // Total number of important profile fields
  int filledFields = 0;
  
  if (professional.firstName.isNotEmpty) filledFields++;
  if (professional.lastName.isNotEmpty) filledFields++;
  if (professional.address.isNotEmpty) filledFields++;
  if (professional.phoneN.isNotEmpty) filledFields++;
  if (professional.dni.isNotEmpty) filledFields++;
  if (professional.license.isNotEmpty) filledFields++;
  if (professional.workDays.isNotEmpty) filledFields++;
  if (professional.startTime.isNotEmpty && professional.endTime.isNotEmpty) filledFields++;
  
  return filledFields / totalFields;
});

/// Helper function to get the last appointment date for a patient
String _getLastAppointmentDate(List<QueryDocumentSnapshot> docs, String patientId) {
  final patientAppointments = docs
      .where((doc) => (doc.data() as Map<String, dynamic>)['patientId'] == patientId)
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
  final String? breakDuration; // Add this field
  final bool isLoading;
  final bool hasData;
  final bool isEditing;
  final String? error;

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
    this.breakDuration, // Add this parameter to constructor
    this.isLoading = false,
    this.hasData = false,
    this.isEditing = false,
    this.error, // Add this parameter
  });

  // Update the copyWith method to include the breakDuration parameter
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
    String? breakDuration, // Add this parameter
    bool? isLoading,
    bool? hasData,
    bool? isEditing,
    String? error, // Add this parameter
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
      breakDuration: breakDuration ?? this.breakDuration, // Use the parameter
      isLoading: isLoading ?? this.isLoading,
      hasData: hasData ?? this.hasData,
      isEditing: isEditing ?? this.isEditing,
      error: error ?? this.error,
    );
  }
}

/// Notifier class for professional state
class ProfessionalNotifier extends StateNotifier<AsyncValue<ProfessionalModel?>> {
  final WebFirestoreService _firestoreService;

  ProfessionalNotifier(this._firestoreService)
      : super(const AsyncValue.loading()) {
    _loadUserData(); // Load professional data when initialized
  }

  /// Load professional data from Firestore
  Future<void> _loadUserData() async {
    try {
      state = const AsyncValue.loading();
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = AsyncValue.error("No user logged in", StackTrace.current);
        return;
      }

      final doc = await _firestoreService.getDocument('doctors', user.uid);
      
      if (doc != null && doc.exists) {
        // Use the factory constructor to create a model from Firestore data
        final professional = ProfessionalModel.fromFirestore(doc);
        state = AsyncValue.data(professional);
      } else {
        state = AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error loading professional data', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Save professional data to Firestore
  Future<void> saveUserData({
    String? firstName,
    String? lastName,
    String? address,
    String? phoneN,
    String? dni,
    String? license,
    List<String>? workDays,
    String? startTime,
    String? endTime,
    int? breakDuration,
    String? speciality,
  }) async {
    try {
      // Create a loading state that preserves the current data
      state = AsyncValue<ProfessionalModel?>.loading().copyWithPrevious(state);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      
      // Get current model or create a minimal one
      final currentModel = state.value ?? ProfessionalModel(
        uid: user.uid,
        firstName: '',
        lastName: '',
        email: user.email ?? '',
        phoneN: '',
        dni: '',
        address: '',
        license: '',
        speciality: '',
        workDays: [],
        startTime: '09:00',
        endTime: '17:00',
      );
      
      // Create updated model using copyWith
      final updatedModel = currentModel.copyWith(
        firstName: firstName,
        lastName: lastName,
        address: address,
        phoneN: phoneN,
        dni: dni,
        license: license,
        speciality: speciality,
        workDays: workDays,
        startTime: startTime,
        endTime: endTime,
        breakDuration: breakDuration,
        profileCompleted: true,
      );
      
      // Save to Firestore using the model's toFirestore method
      await _firestoreService.updateDocument(
        'doctors',
        user.uid,
        updatedModel.toFirestore(),
      );
      
      // Update state with the new model
      state = AsyncValue.data(updatedModel);
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error saving professional data', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Reload professional data
  Future<void> refresh() async {
    await _loadUserData();
  }
}