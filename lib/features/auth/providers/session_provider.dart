// lib/features/auth/providers/session_provider.dart

import 'dart:async';
import 'package:Psiconnect/core/constants/app_constants.dart';
import 'package:Psiconnect/navigation/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Provider to check if user has admin role
final isAdminProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.role == 'admin';
});

/// Provider to check if user is a professional
final isProfessionalProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.role == 'professional';
});

/// Provider to check if user is a patient
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
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        // Usuario desconectado
        state = null;
      } else {
        try {
          // Determinar el rol buscando al usuario en las colecciones existentes
          String role = 'guest';
          String displayName = user.displayName ?? '';
          String email = user.email ?? '';
          
          // Verificar si es un doctor (la colección se llama doctors)
          final doctorDoc = await _firestore
              .collection('doctors')
              .doc(user.uid)
              .get();
              
          if (doctorDoc.exists) {
            role = 'professional'; // Importante: Usa 'professional', no 'doctor'
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            displayName = '${doctorData['firstName'] ?? ''} ${doctorData['lastName'] ?? ''}'.trim();
            email = doctorData['email'] ?? email;
          } else {
            // Verificar si es un paciente
            final patientDoc = await _firestore
                .collection('patients')
                .doc(user.uid)
                .get();
                
            if (patientDoc.exists) {
              role = 'patient';
              final patientData = patientDoc.data() as Map<String, dynamic>;
              displayName = '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
              email = patientData['email'] ?? email;
            } else {
              // Verificar si es un administrador
              final adminDoc = await _firestore
                  .collection('admins')
                  .doc(user.uid)
                  .get();
                  
              if (adminDoc.exists) {
                role = 'admin';
              }
            }
          }
          
          // Crear la sesión de usuario con el rol determinado
          if (mounted) {
            state = UserSession(
              uid: user.uid,
              email: email,
              displayName: displayName,
              role: role,
              photoURL: user.photoURL,
            );
            
            print('Sesión creada con rol: $role para el usuario ${user.uid}');
          }
        } catch (e, stackTrace) {
          print('Error cargando sesión de usuario: $e');
          
          // Sesión básica con solo datos de autenticación
          if (mounted) {
            state = UserSession(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? '',
              role: 'guest', // Por defecto es invitado
              photoURL: user.photoURL,
            );
          }
        }
      }
    });
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
      // Determine which collection to check based on role
      String collection;
      if (role == 'professional') {
        collection = FirestoreCollections.doctors;
      } else if (role == 'patient') {
        collection = FirestoreCollections.patients;
      } else {
        // For other roles, consider what makes sense in your application
        return false;
      }
      
      // Query Firestore to see if there's a user with this DNI in the specified collection
      final querySnapshot = await _firestore
          .collection(collection)
          .where('dni', isEqualTo: dni)
          .get();
      
      // If we found any documents, the DNI already exists for this role
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking DNI existence: $e');
      // If there's an error, it's safer to assume the DNI might exist
      // to prevent duplicate registrations
      return true;
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
  Future<void> logInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      // State will be updated by the auth listener
    } catch (e) {
      print('Error durante el login con Google: $e'); // Debug log
      rethrow; // Let the UI handle the error
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

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}