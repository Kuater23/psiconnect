// lib/features/patient/providers/patient_providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/services/web_firestore_service.dart';
import '/core/exceptions/app_exception.dart';
import '/core/services/error_logger.dart';
import '/features/appointments/models/appointment.dart';
import '/features/auth/providers/session_provider.dart';

/// Patient profile data class
class PatientProfile {
  final String? uid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneN;
  final String? dni;
  final DateTime? dob;
  
  PatientProfile({
    this.uid,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneN,
    this.dni,
    this.dob,
  });
  
  /// Create PatientProfile from Firestore data
  factory PatientProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      return PatientProfile();
    }
    
    DateTime? birthDate;
    if (data['dob'] != null) {
      if (data['dob'] is Timestamp) {
        birthDate = (data['dob'] as Timestamp).toDate();
      } else if (data['dob'] is String) {
        try {
          birthDate = DateTime.parse(data['dob']);
        } catch (e) {
          // Invalid date format
        }
      }
    }
    
    return PatientProfile(
      uid: doc.id,
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      phoneN: data['phoneN'],
      dni: data['dni'],
      dob: birthDate,
    );
  }
  
  /// Convert profile to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneN': phoneN,
      'dni': dni,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
  
  /// Create a copy with updated fields
  PatientProfile copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneN,
    String? dni,
    DateTime? dob,
  }) {
    return PatientProfile(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneN: phoneN ?? this.phoneN,
      dni: dni ?? this.dni,
      dob: dob ?? this.dob,
    );
  }
}

/// Provider for patient profile data
final patientProfileProvider = StateNotifierProvider<PatientProfileNotifier, AsyncValue<PatientProfile>>((ref) {
  final user = ref.watch(sessionProvider);
  
  if (user == null || user.role != 'patient') {
    return PatientProfileNotifier(null, WebFirestoreService());
  }
  
  return PatientProfileNotifier(user.uid, WebFirestoreService());
});

/// Provider for patient's upcoming appointments
final patientUpcomingAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  final user = ref.watch(sessionProvider);
  
  if (user == null || user.role != 'patient') {
    return Stream.value([]);
  }
  
  final patientId = user.uid;
  final now = DateTime.now();
  
  try {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('patient_id', isEqualTo: patientId)
        .where('date', isGreaterThan: now.toIso8601String())
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('date')
        .limit(5)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList()
        );
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching patient upcoming appointments', e, stackTrace);
    return Stream.value([]);
  }
});

/// Provider for patient's past appointments
final patientPastAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  final user = ref.watch(sessionProvider);
  
  if (user == null || user.role != 'patient') {
    return Stream.value([]);
  }
  
  final patientId = user.uid;
  final now = DateTime.now();
  
  try {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('patient_id', isEqualTo: patientId)
        .where('date', isLessThan: now.toIso8601String())
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList()
        );
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching patient past appointments', e, stackTrace);
    return Stream.value([]);
  }
});

/// Provider for filtered patient appointments
final patientFilteredAppointmentsProvider = Provider.family<List<Appointment>, String>((ref, filter) {
  final upcomingAppointments = ref.watch(patientUpcomingAppointmentsProvider);
  final pastAppointments = ref.watch(patientPastAppointmentsProvider);
  
  return upcomingAppointments.when(
    data: (upcoming) {
      return pastAppointments.when(
        data: (past) {
          // Combine and filter appointments
          final List<Appointment> allAppointments = [...upcoming, ...past];
          
          if (filter == 'all') return allAppointments;
          return allAppointments.where((appointment) => appointment.status == filter).toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for patient medical records
final patientMedicalRecordsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(sessionProvider);
  
  if (user == null || user.role != 'patient') {
    return Stream.value([]);
  }
  
  final patientId = user.uid;
  
  try {
    return FirebaseFirestore.instance
        .collection('medical_history')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList()
        );
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching patient medical records', e, stackTrace);
    return Stream.value([]);
  }
});

/// Provider for patient documents
final patientDocumentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(sessionProvider);
  
  if (user == null || user.role != 'patient') {
    return Stream.value([]);
  }
  
  final patientId = user.uid;
  
  try {
    return FirebaseFirestore.instance
        .collection('patient_documents')
        .where('patientId', isEqualTo: patientId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList()
        );
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error fetching patient documents', e, stackTrace);
    return Stream.value([]);
  }
});

/// Provider for professional search results
final professionalSearchProvider = StateNotifierProvider<ProfessionalSearchNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ProfessionalSearchNotifier();
});

/// Provider for patient profile completion status
final patientProfileCompletionProvider = Provider.autoDispose<double>((ref) {
  final profileData = ref.watch(patientProfileProvider);
  
  return profileData.when(
    data: (profile) {
      // Calculate completion percentage
      int totalFields = 6; // Total number of important profile fields
      int filledFields = 0;
      
      if (profile.firstName?.isNotEmpty ?? false) filledFields++;
      if (profile.lastName?.isNotEmpty ?? false) filledFields++;
      if (profile.phoneN?.isNotEmpty ?? false) filledFields++;
      if (profile.dni?.isNotEmpty ?? false) filledFields++;
      if (profile.email?.isNotEmpty ?? false) filledFields++;
      if (profile.dob != null) filledFields++;
      
      return filledFields / totalFields;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Notifier for patient profile
class PatientProfileNotifier extends StateNotifier<AsyncValue<PatientProfile>> {
  final String? _userId;
  final WebFirestoreService _firestoreService;
  
  PatientProfileNotifier(this._userId, this._firestoreService) : super(AsyncValue.loading()) {
    if (_userId != null) {
      _loadPatientData();
    } else {
      state = AsyncValue.data(PatientProfile());
    }
  }
  
  /// Load patient data from Firestore
  Future<void> _loadPatientData() async {
    try {
      state = AsyncValue.loading();
      
      final doc = await _firestoreService.getDocument('patients', _userId!);
      
      if (doc == null || !doc.exists) {
        // Check if user exists in users collection
        final userDoc = await _firestoreService.getDocument('users', _userId!);
        
        if (userDoc != null && userDoc.exists) {
          // Create a new patient document
          final userData = userDoc.data() as Map<String, dynamic>?;
          
          if (userData != null) {
            await _firestoreService.setDocument(
              'patients',
              _userId!,
              {
                'firstName': userData['firstName'] ?? '',
                'lastName': userData['lastName'] ?? '',
                'email': userData['email'] ?? '',
                'uid': _userId,
                'createdAt': FieldValue.serverTimestamp(),
              },
            );
            
            // Reload data
            _loadPatientData();
            return;
          }
        }
        
        state = AsyncValue.data(PatientProfile(uid: _userId));
        return;
      }
      
      state = AsyncValue.data(PatientProfile.fromFirestore(doc));
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error loading patient data', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Update patient profile
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneN,
    required String dni,
    DateTime? dob,
  }) async {
    try {
      if (_userId == null) return;
      
      // Get current state data
      final currentData = state.value;
      if (currentData == null) return;
      
      // Update state with loading
      state = AsyncValue.loading();
      
      // Create updated profile
      final updatedProfile = currentData.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneN: phoneN,
        dni: dni,
        dob: dob,
      );
      
      // Save to Firestore
      await _firestoreService.updateDocument(
        'patients',
        _userId!,
        updatedProfile.toFirestore(),
      );
      
      // Update state with new data
      state = AsyncValue.data(updatedProfile);
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error updating patient profile', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
      throw DataException('Error updating profile: ${e.toString()}');
    }
  }
  
  /// Refresh patient data
  Future<void> refresh() async {
    if (_userId != null) {
      await _loadPatientData();
    }
  }
}

/// Notifier for professional search
class ProfessionalSearchNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  ProfessionalSearchNotifier() : super(AsyncValue.data([]));
  
  /// Search for professionals
  Future<void> searchProfessionals({
    String? name,
    String? speciality,
  }) async {
    try {
      state = AsyncValue.loading();
      
      Query query = FirebaseFirestore.instance
          .collection('doctors'); 
      
      if (speciality != null && speciality.isNotEmpty) {
        query = query.where('speciality', isEqualTo: speciality);
      }
      
      final snapshot = await query.get();
      
      final professionals = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Filter by name if provided
            if (name != null && name.isNotEmpty) {
              final fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.toLowerCase();
              if (!fullName.contains(name.toLowerCase())) {
                return null;
              }
            }
            
            return {
              'id': doc.id,
              'name': data['firstName'] ?? '',
              'lastName': data['lastName'] ?? '',
              'speciality': data['speciality'] ?? 'Psicología',
              'rating': data['rating'] ?? 0.0,
            };
          })
          .where((item) => item != null)
          .cast<Map<String, dynamic>>()
          .toList();
      
      state = AsyncValue.data(professionals);
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error searching professionals', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Clear search results
  void clearSearch() {
    state = AsyncValue.data([]);
  }
}