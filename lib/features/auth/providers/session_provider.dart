// lib/features/auth/providers/session_provider.dart

import 'dart:async';
import 'package:Psiconnect/core/constants/app_constants.dart';
import 'package:Psiconnect/features/patient/models/patient_model.dart';
import 'package:Psiconnect/features/professional/models/professional_model.dart';
import 'package:Psiconnect/navigation/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/core/exceptions/app_exception.dart';
import '/features/auth/models/user_session.dart';
import '/features/auth/services/auth_service.dart';
import '/core/services/error_logger.dart';

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

// User session provider
final sessionProvider = StateNotifierProvider<SessionNotifier, UserSession?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firestore = FirebaseFirestore.instance;
  return SessionNotifier(authService, firestore);
});

// User role provider for easy access
final userRoleProvider = Provider<String>((ref) {
  return ref.watch(sessionProvider)?.role ?? 'guest';
});

// User ID provider for easy access
final userIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider)?.uid;
});

// Check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider) != null;
});

// Provider to check if user has admin role
final isAdminProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.role == 'admin';
});

// Provider to check if user is a professional
final isProfessionalProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.role == 'professional';
});

// Provider to check if user is a patient
final isPatientProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.role == 'patient';
});

class SessionNotifier extends StateNotifier<UserSession?> {
  final AuthService _authService;
  final FirebaseFirestore _firestore;
  
  // Store subscription for later disposal
  late final StreamSubscription<User?> _authSubscription;

  SessionNotifier(this._authService, this._firestore) : super(null) {
    // Brief delay to ensure Firebase is properly initialized
    if (kIsWeb) {
      Future.delayed(Duration(milliseconds: 500), () {
        _initAuthListener();
      });
    } else {
      _initAuthListener();
    }
  }

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      await _onAuthStateChanged(user);
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      state = null;
      return;
    }
    
    try {
      // Check collections to determine role
      String role = 'guest';
      String displayName = user.displayName ?? '';
      String email = user.email ?? '';
      String collection = '';
      Map<String, dynamic>? userData;
      
      // First check if user is a professional (doctors collection)
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(user.uid)
          .get();
          
      if (doctorDoc.exists) {
        role = 'professional';
        collection = 'doctors';
        userData = doctorDoc.data() as Map<String, dynamic>;
        displayName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        email = userData['email'] ?? email;
      } else {
        // Check if user is a patient
        final patientDoc = await _firestore
            .collection('patients')
            .doc(user.uid)
            .get();
            
        if (patientDoc.exists) {
          role = 'patient';
          collection = 'patients';
          userData = patientDoc.data() as Map<String, dynamic>;
          displayName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
          email = userData['email'] ?? email;
        } else {
          // Check if user is an admin
          final adminDoc = await _firestore
              .collection('admins')
              .doc(user.uid)
              .get();
              
          if (adminDoc.exists) {
            role = 'admin';
            collection = 'admins';
            userData = adminDoc.data() as Map<String, dynamic>;
          }
        }
      }
      
      // Now check if profile is complete - only if we found the user
      bool isComplete = false;
      if (collection.isNotEmpty && userData != null) {
        isComplete = await _isProfileComplete(user, role, userData);
      }
      
      // Create session with profile completion status
      final session = UserSession(
        uid: user.uid,
        email: email,
        role: role,
        displayName: displayName,
        isProfileComplete: isComplete,
      );
      
      state = session;
    } catch (e) {
      print('Error in _onAuthStateChanged: $e');
      // Error handling
    }
  }

  // Replace both _isProfileComplete methods with this single implementation
  Future<bool> _isProfileComplete(User user, String role, Map<String, dynamic> userData) async {
    // Check if profileCompleted flag exists and is true
    if (userData['profileCompleted'] == true) return true;
    
    // Model-based checking approach
    if (role == 'professional') {
      try {
        // Try creating a professional model from the data to check fields
        final professionalData = {
          ...userData,
          'uid': user.uid,
        };
        
        // This will throw an exception if required fields are missing
        final professional = ProfessionalModel.fromMap(professionalData);
        
        // Check if all required fields have values
        return professional.firstName.isNotEmpty &&
               professional.lastName.isNotEmpty &&
               professional.phoneN.isNotEmpty &&
               professional.dni.isNotEmpty &&
               professional.address.isNotEmpty &&
               professional.license.isNotEmpty &&
               professional.workDays.isNotEmpty &&
               professional.startTime.isNotEmpty &&
               professional.endTime.isNotEmpty;
      } catch (e) {
        print('Professional profile incomplete: $e');
        
        // Fall back to manual field checking if model approach fails
        final hasRequiredFields = userData['firstName'] != null && 
               userData['lastName'] != null && 
               userData['dni'] != null && 
               userData['phoneN'] != null &&
               userData['address'] != null &&
               userData['license'] != null &&
               userData['startTime'] != null &&
               userData['endTime'] != null;
               
        // Check either workDays or workDays (for backward compatibility)
        final hasWorkDays = (userData['workDays'] != null && (userData['workDays'] as List).isNotEmpty) ||
                            (userData['workdays'] != null && (userData['workdays'] as List).isNotEmpty);
               
        return hasRequiredFields && hasWorkDays;
      }
    } else if (role == 'patient') {
      try {
        // Try creating a patient model from the data to check fields
        final patientData = {
          ...userData,
          'uid': user.uid,
        };
        
        // This will throw an exception if required fields are missing
        final patient = PatientModel.fromMap(patientData);
        
        // Check if all required fields have values
        return patient.firstName.isNotEmpty &&
               patient.lastName.isNotEmpty &&
               patient.phoneN.isNotEmpty &&
               patient.dni.isNotEmpty &&
               patient.dob != null;
      } catch (e) {
        print('Patient profile incomplete: $e');
        
        // Fall back to manual field checking
        return userData['firstName'] != null && 
               userData['lastName'] != null && 
               userData['dni'] != null && 
               userData['phoneN'] != null;
      }
    } else if (role == 'admin') {
      // For admin users, we might have different requirements
      return true;
    }
    
    // Default case - if role is not recognized
    return false;
  }
  
  // Helper to extract full name from doc data
  String _getFullName(Map<String, dynamic> data) {
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return '';
  }
  
  // Create a default patient record if user doesn't exist in any collection
  Future<void> _createPatientRecord(User user) async {
    try {
      // Crear un documento de paciente con los datos básicos
      await _firestore.collection('patients').doc(user.uid).set({
        'firstName': user.displayName?.split(' ').firstOrNull ?? '',
        'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
        'email': user.email ?? '',
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'registerMethod': 'auto',
      });
      
      print('Created default patient record for new user'); // Debug log
    } catch (e) {
      print('Error creating default patient record: $e'); // Debug log
    }
  }
  
  // New method to check for existing DNI in a specific role collection
  Future<bool> checkDniExists({required String dni, required String role}) async {
    try {
      // Skip the check if DNI is empty (common for Google sign-ins)
      if (dni.isEmpty) {
        return false;
      }
      
      String collection;
      if (role == 'professional') {
        collection = 'doctors';  // Use string directly instead of FirestoreCollections
      } else if (role == 'patient') {
        collection = 'patients';
      } else {
        return false;
      }
      
      print('Checking for DNI: $dni in collection: $collection');
      final querySnapshot = await _firestore
          .collection(collection)
          .where('dni', isEqualTo: dni)
          .get();
      
      // Debug information
      print('Found ${querySnapshot.docs.length} documents with this DNI');
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking DNI existence: $e');
      // Return false on error instead of true to avoid false positives
      return false;
    }
  }
  
  // Método login
  Future<void> logIn(String email, String password) async {
    try {
      // Solo llama al método de inicio de sesión, el resto se maneja en el listener
      final user = await _authService.signInWithEmail(email, password);
      // No tienes que configurar el state aquí - se hará automáticamente por el listener
      
      print('Login exitoso para $email');
    } catch (e) {
      print('Error durante el login: $e');
      rethrow; // Deja que la UI maneje el error
    }
  }
  
  // Login with Google
  Future<User?> logInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        // Verificar si el usuario ya existe en alguna colección
        final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
        final patientDoc = await _firestore.collection('patients').doc(user.uid).get();
        
        if (!doctorDoc.exists && !patientDoc.exists) {
          // Es un usuario nuevo, devuelve el usuario para que la UI muestre el diálogo de rol
          print('Nuevo usuario de Google detectado, requiere selección de rol');
          return user;
        } else {
          // Es un usuario existente, el listener de autenticación se encargará de redireccionar
          print('Usuario existente de Google encontrado en las colecciones');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error durante el login con Google: $e');
      rethrow;
    }
  }
  
  // Register new user
  Future<void> register({
    required String email, 
    required String password, 
    required String role,
    String firstName = '',
    String lastName = '',
    String phoneN = '',
    String dni = '',
    DateTime? dob,
    // Campos específicos para doctores
    String? license,
    String? speciality,
    String? startTime,
    String? endTime,
    List<String>? workDays,
    String? breakDuration,
  }) async {
    try {
      // Create authentication user
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
      );
      
      if (user == null) {
        throw AuthException('Error al crear usuario');
      }
      
      // Create common user data
      Map<String, dynamic> userData = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'uid': user.uid,
        'phoneN': phoneN,
        'dni': dni,
        'createdAt': FieldValue.serverTimestamp(),
        'profileCompleted': false, // Añadir este campo explícitamente
      };
      
      // Add dob if provided
      if (dob != null) {
        userData['dob'] = Timestamp.fromDate(dob);
      }
      
      // Determinar en qué colección guardar basado en el rol
      String collection;
      
      if (role == 'professional') {
        collection = 'doctors';
        
        // Add doctor-specific fields
        if (license != null) userData['license'] = license;
        if (speciality != null) userData['speciality'] = speciality;
        if (startTime != null) userData['startTime'] = startTime;
        if (endTime != null) userData['endTime'] = endTime;
        if (breakDuration != null) userData['breakDuration'] = breakDuration;
        
        if (workDays != null && workDays.isNotEmpty) {
          userData['workDays'] = workDays;
        }
      } else if (role == 'admin') {
        collection = 'admins';
      } else {
        // Default to patient
        collection = 'patients';
      }
      
      // Crear documento en la colección correspondiente
      await _firestore.collection(collection).doc(user.uid).set(userData);
      
      // Also update user profile in Firebase Auth
      await user.updateDisplayName('$firstName $lastName'.trim());
      
      print('Created new user in collection: $collection'); // Debug log
      
      // Estado se actualizará a través del auth listener
    } catch (e) {
      print('Error during registration: $e'); // Debug log
      rethrow; // Let the UI handle the error
    }
  }
  
  // Add a new method for Google registration with role selection
  Future<void> registerWithGoogle(String role) async {
  // Get the currently signed in user
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('Error: No user logged in when trying to register with Google');
    return;
  }

  // First check if user already exists in any collection
  final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
  final patientDoc = await _firestore.collection('patients').doc(user.uid).get();
  
  if (doctorDoc.exists || patientDoc.exists) {
    print('User already exists in a collection. Not creating a new record.');
    return;
  }

  // Determine which collection to use based on role
  final String collection = role == 'professional' ? 'doctors' : 'patients';
  
  // Extract name parts from display name
  final nameParts = user.displayName?.split(' ') ?? [''];
  final firstName = nameParts.firstOrNull ?? '';
  final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
  
  // Create user data map
  Map<String, dynamic> userData = {
    'firstName': firstName,
    'lastName': lastName,
    'email': user.email ?? '',
    'uid': user.uid,
    'createdAt': FieldValue.serverTimestamp(),
    'registerMethod': 'google',
    'profileCompleted': false, // Set to false for new users
  };
  
  // For debugging - print clear information
  print('Creating user in collection: $collection with role determined by collection');
  
  // Create user in the appropriate collection only
  await _firestore.collection(collection).doc(user.uid).set(userData);
  
  print('Successfully created Google user in collection: $collection');
}
  
  // Log out
  // Log out - use this method instead of signOut
Future<void> logOut([BuildContext? context]) async {
  try {
    // Sign out directly from Firebase Auth
    await FirebaseAuth.instance.signOut();
    
    // Show success message if context is provided
    if (context != null && context.mounted) {
      context.go(RoutePaths.home);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has cerrado sesión correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    print('Error during logout: $e');
    
    // Show error message if context is provided
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cerrar sesión'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    rethrow;
  }
}

  /// Reload the current user session to reflect any changes in profile completion
  Future<void> reloadSession() async {
    try {
      // Get current Firebase user
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        print('No hay usuario autenticado para recargar la sesión');
        return;
      }
      
      // Force reload of Firebase user to get latest token claims
      await user.reload();
      
      // Re-run the auth state changed handler with the current user
      // This will check collections again and update isProfileComplete
      await _onAuthStateChanged(user);
      
      print('Sesión recargada exitosamente para: ${user.email}');
    } catch (e) {
      print('Error al recargar la sesión: $e');
      ErrorLogger.logError('Error reloading session', e, StackTrace.current);
      throw AppException('No se pudo recargar la sesión: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}