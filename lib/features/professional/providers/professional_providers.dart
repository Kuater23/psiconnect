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

/// Provider for professional profile data
final professionalProvider = StateNotifierProvider<ProfessionalNotifier, AsyncValue<ProfessionalModel?>>((ref) {
  final session = ref.watch(sessionProvider);
  
  if (session == null || session.role != 'professional') {
    return ProfessionalNotifier(null, WebFirestoreService());
  }
  
  return ProfessionalNotifier(session.uid, WebFirestoreService());
});

/// Provider for professional availability
final professionalAvailabilityProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, doctorId) async {
  try {
    final firestoreService = WebFirestoreService();
    final doc = await firestoreService.getDocument('doctors', doctorId);
    
    if (doc == null || !doc.exists) {
      return [];
    }
    
    final data = doc.data() as Map<String, dynamic>;
    final availability = data['availability'] as Map<String, dynamic>? ?? {};
    
    final List<String> workDays = List<String>.from(availability['workDays'] ?? []);
    final String startTime = availability['startTime'] ?? '09:00';
    final String endTime = availability['endTime'] ?? '17:00';
    final int breakDuration = availability['breakDuration'] ?? 30;
    
    // Generate time slots for each available day
    final List<Map<String, dynamic>> availableSlots = [];
    
    for (final day in workDays) {
      availableSlots.add({
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'breakDuration': breakDuration,
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
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('status', whereIn: ['pending', 'scheduled'])
        .orderBy('scheduledAt')
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

/// Provider for professional's past appointments
final professionalPastAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
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
        .where('scheduledAt', isLessThan: Timestamp.fromDate(now))
        .orderBy('scheduledAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList()
        );
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching professional past appointments', e, stackTrace);
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
              .map((doc) => (doc.data())['patientId'] as String)
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
                'phoneN': patientData['phoneN'] ?? '',
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
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    
    // Get upcoming appointments
    final upcomingAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('status', whereIn: ['pending', 'scheduled'])
        .get();
    
    // Calculate stats
    final int totalMonthlyAppointments = monthlyAppointments.docs.length;
    final int upcomingCount = upcomingAppointments.docs.length;
    
    // Count appointments by status
    int completedCount = 0;
    int cancelledCount = 0;
    
    for (final doc in monthlyAppointments.docs) {
      final data = doc.data();
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

/// Provider for professional profile completion status
final professionalProfileCompletionProvider = Provider.autoDispose<double>((ref) {
  final professionalState = ref.watch(professionalProvider);
  
  return professionalState.when(
    data: (professional) {
      if (professional == null) return 0.0;
      
      // Calculate completion percentage based on filled fields
      int totalFields = 7; // Total number of important profile fields
      int filledFields = 0;
      
      if (professional.firstName?.isNotEmpty ?? false) filledFields++;
      if (professional.lastName?.isNotEmpty ?? false) filledFields++;
      if (professional.consultingAddress?.isNotEmpty ?? false) filledFields++;
      if (professional.phoneN?.isNotEmpty ?? false) filledFields++;
      if (professional.dni?.isNotEmpty ?? false) filledFields++;
      if (professional.licenseNumber?.isNotEmpty ?? false) filledFields++;
      if (professional.availability != null && professional.availability!.isNotEmpty) filledFields++;
      
      return filledFields / totalFields;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Helper function to get the last appointment date for a patient
String _getLastAppointmentDate(List<QueryDocumentSnapshot> docs, String patientId) {
  final patientAppointments = docs
      .where((doc) => (doc.data() as Map<String, dynamic>)['patientId'] == patientId)
      .toList();
      
  if (patientAppointments.isEmpty) return 'N/A';
  
  patientAppointments.sort((a, b) {
    final timestampA = (a.data() as Map<String, dynamic>)['scheduledAt'] as Timestamp?;
    final timestampB = (b.data() as Map<String, dynamic>)['scheduledAt'] as Timestamp?;
    
    if (timestampA == null || timestampB == null) return 0;
    
    return timestampB.compareTo(timestampA); // Sort in descending order
  });
  
  final lastAppointmentTimestamp = (patientAppointments.first.data() as Map<String, dynamic>)['scheduledAt'] as Timestamp?;
  
  if (lastAppointmentTimestamp == null) return 'N/A';
  
  // Format the date
  try {
    final dateTime = lastAppointmentTimestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  } catch (e) {
    return 'N/A';
  }
}

/// Helper function to get month name
String _getMonthName(int month) {
  const monthNames = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  
  return month >= 1 && month <= 12 ? monthNames[month] : '';
}

/// Notifier class for professional state
class ProfessionalNotifier extends StateNotifier<AsyncValue<ProfessionalModel?>> {
  final String? _userId;
  final WebFirestoreService _firestoreService;

  ProfessionalNotifier(this._userId, this._firestoreService) 
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _loadProfessionalData();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Load professional data from Firestore
  Future<void> _loadProfessionalData() async {
    try {
      state = const AsyncValue.loading();
      
      if (_userId == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final doc = await _firestoreService.getDocument('doctors', _userId!);
      
      if (doc == null || !doc.exists) {
        state = const AsyncValue.data(null);
        return;
      }
      
      // ✅ Use ProfessionalModel.fromFirestore correctly
      final professional = ProfessionalModel.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>
      );
      state = AsyncValue.data(professional);
      
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error loading professional data', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update professional profile
  /// ✅ Usa nombres de campos correctos según ProfessionalModel
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? consultingAddress,
    String? phoneN,
    String? dni,
    String? licenseNumber,
    String? speciality,
    String? bio,
    Map<String, dynamic>? availability,
    double? consultationFee,
  }) async {
    try {
      if (_userId == null) return;
      
      // Get current state data
      final currentData = state.value;
      if (currentData == null) return;
      
      // Update state with loading but preserve previous data
      state = AsyncValue<ProfessionalModel?>.loading().copyWithPrevious(state);
      
      // ✅ Create updated profile using copyWith with correct field names
      final updatedProfile = currentData.copyWith(
        firstName: firstName,
        lastName: lastName,
        consultingAddress: consultingAddress,
        phoneN: phoneN,
        dni: dni,
        licenseNumber: licenseNumber,
        speciality: speciality,
        bio: bio,
        availability: availability,
        consultationFee: consultationFee,
        profileCompleted: true,
        status: 'active',
      );
      
      // ✅ Save to Firestore using toMap from BaseModel
      await _firestoreService.updateDocument(
        'doctors',
        _userId!,
        updatedProfile.toMap(),
      );
      
      // Update state with new data
      state = AsyncValue.data(updatedProfile);
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error updating professional profile', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
      throw DataException('Error updating profile: ${e.toString()}');
    }
  }

  /// Refresh professional data
  Future<void> refresh() async {
    if (_userId != null) {
      await _loadProfessionalData();
    }
  }
}