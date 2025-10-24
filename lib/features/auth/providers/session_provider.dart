// lib/features/auth/providers/session_provider.dart

import 'dart:async';
import 'package:Psiconnect/core/constants/app_constants.dart';
import 'package:Psiconnect/features/patient/models/patient_model.dart';
import 'package:Psiconnect/features/professional/models/professional_model.dart';
import 'package:Psiconnect/navigation/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/core/exceptions/app_exception.dart';
import '/features/auth/models/user_session.dart';
import '/features/auth/services/auth_service.dart';
import '/core/services/error_logger.dart';
import '../../../core/services/user_role_service.dart';
import '../../../core/providers/base_provider.dart';

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
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
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
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
    } catch (e, st) {
      ErrorLogger.logError('Error in _onAuthStateChanged', e, st);
    }
  }

  // ✅ MÉTODO CORREGIDO - Usa fromFirestore en lugar de fromMap
  Future<bool> _isProfileComplete(User user, String role, Map<String, dynamic> userData) async {
    // ✅ Primera verificación: flag profileCompleted
    if (userData['profileCompleted'] == true) {
      return true;
    }
    
    // ✅ Segunda verificación: validación basada en modelo
    if (role == 'professional') {
      try {
        final docRef = _firestore.collection('doctors').doc(user.uid);
        final snapshot = await docRef.get();
        
        if (!snapshot.exists) {
          return false;
        }
        
        final professional = ProfessionalModel.fromFirestore(
          snapshot as DocumentSnapshot<Map<String, dynamic>>
        );
        
        // ✅ Usar el helper del modelo
        final isComplete = professional.isProfileComplete;
        
        // Si está completo pero no está marcado, actualizarlo
        if (isComplete && !professional.profileCompleted) {
          await _firestore.collection('doctors').doc(user.uid).update({
            'profileCompleted': true,
          });
        }
        
        return isComplete;
      } catch (e, st) {
        ErrorLogger.logError('Professional profile incomplete', e, st);
        
        // Fall back to manual field checking
        final hasRequiredFields = userData['firstName'] != null && 
               userData['lastName'] != null && 
               userData['dni'] != null && 
               userData['phoneN'] != null &&
               userData['consultingAddress'] != null &&
               userData['licenseNumber'] != null;
               
        final hasAvailability = userData['availability'] != null && 
                                (userData['availability'] as Map).isNotEmpty;
               
        return hasRequiredFields && hasAvailability;
      }
    } else if (role == 'patient') {
      try {
        final docRef = _firestore.collection('patients').doc(user.uid);
        final snapshot = await docRef.get();
        
        if (!snapshot.exists) {
          return false;
        }
        
        final patient = PatientModel.fromFirestore(
          snapshot as DocumentSnapshot<Map<String, dynamic>>
        );
        
        // ✅ Usar el helper del modelo
        final isComplete = patient.isProfileComplete;
        
        // Si está completo pero no está marcado, actualizarlo
        if (isComplete && !patient.profileCompleted) {
          await _firestore.collection('patients').doc(user.uid).update({
            'profileCompleted': true,
          });
        }
        
        return isComplete;
      } catch (e, st) {
        ErrorLogger.logError('Patient profile incomplete', e, st);
        
        // Fall back to manual field checking
        return userData['firstName'] != null && 
               userData['lastName'] != null && 
               userData['dni'] != null && 
               userData['phoneN'] != null &&
               userData['birthDate'] != null;
      }
    } else if (role == 'admin') {
      return true;
    }
    
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
      
      ErrorLogger.info('Created default patient record for new user');
    } catch (e, st) {
      ErrorLogger.logError('Error creating default patient record', e, st);
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
        collection = 'doctors';
      } else if (role == 'patient') {
        collection = 'patients';
      } else {
        return false;
      }
      
      ErrorLogger.info('Checking for DNI: $dni in collection: $collection');
      final querySnapshot = await _firestore
          .collection(collection)
          .where('dni', isEqualTo: dni)
          .get();
      
      ErrorLogger.info('Found ${querySnapshot.docs.length} documents with this DNI');
      return querySnapshot.docs.isNotEmpty;
    } catch (e, st) {
      ErrorLogger.logError('Error checking DNI existence', e, st);
      return false;
    }
  }
  
  // Método login
  Future<void> logIn(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      
      ErrorLogger.info('Login exitoso para ${user?.email ?? email}');
    } catch (e, st) {
      ErrorLogger.logError('Error durante el login', e, st);
      rethrow;
    }
  }
  
  // Login with Google
  Future<User?> logInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        ErrorLogger.info('Google sign-in aborted by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
        final patientDoc = await _firestore.collection('patients').doc(user.uid).get();
        
        if (!doctorDoc.exists && !patientDoc.exists) {
          ErrorLogger.info('Nuevo usuario de Google detectado, requiere selección de rol');
          return user;
        } else {
          ErrorLogger.info('Usuario existente de Google encontrado en las colecciones');
          return null;
        }
      }
      return null;
    } catch (e, st) {
      ErrorLogger.logError('Error durante el login con Google', e, st);
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
    String? license,
    String? speciality,
    Map<String, dynamic>? availability,
  }) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      
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
        'updatedAt': FieldValue.serverTimestamp(),
        'profileCompleted': false,
      };
      
      // Add birthDate if provided
      if (dob != null) {
        userData['birthDate'] = Timestamp.fromDate(dob);
      }
      
      String collection;
      
      if (role == 'professional') {
        collection = 'doctors';
        
        if (license != null) userData['licenseNumber'] = license;
        if (speciality != null) userData['speciality'] = speciality;
        if (availability != null) userData['availability'] = availability;
      } else if (role == 'admin') {
        collection = 'admins';
      } else {
        collection = 'patients';
      }
      
      await _firestore.collection(collection).doc(user.uid).set(userData);
      await user.updateDisplayName('$firstName $lastName'.trim());
      
      ErrorLogger.info('Created new user in collection: $collection');
    } catch (e, st) {
      ErrorLogger.logError('Error during registration', e, st);
      rethrow;
    }
  }
  
  // Add a new method for Google registration with role selection
  Future<void> registerWithGoogle(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ErrorLogger.warning('No user logged in when trying to register with Google');
      return;
    }

    final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
    final patientDoc = await _firestore.collection('patients').doc(user.uid).get();
    
    if (doctorDoc.exists || patientDoc.exists) {
      ErrorLogger.warning('User already exists in a collection');
      return;
    }

    final String collection = role == 'professional' ? 'doctors' : 'patients';
    
    final nameParts = user.displayName?.split(' ') ?? [''];
    final firstName = nameParts.firstOrNull ?? '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    Map<String, dynamic> userData = {
      'firstName': firstName,
      'lastName': lastName,
      'email': user.email ?? '',
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'registerMethod': 'google',
      'profileCompleted': false,
    };
    
    await _firestore.collection(collection).doc(user.uid).set(userData);
    
    ErrorLogger.info('Successfully created Google user in collection: $collection');
  }
  
  // Log out
  Future<void> logOut([BuildContext? context]) async {
    try {
      await FirebaseAuth.instance.signOut();
      
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
    } catch (e, st) {
      ErrorLogger.logError('Error during logout', e, st);
      
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
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        ErrorLogger.warning('No hay usuario autenticado para recargar la sesión');
        return;
      }
      
      await user.reload();
      await _onAuthStateChanged(user);
      
      ErrorLogger.info('Sesión recargada exitosamente para: ${user.email}');
    } catch (e, st) {
      ErrorLogger.logError('Error reloading session', e, st);
      throw AppException('No se pudo recargar la sesión: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

class SessionProvider extends BaseProvider {
  final _auth = FirebaseAuth.instance;
  final _roleService = UserRoleService();

  User? _user;
  AppUserRole? _role;

  User? get user => _user;
  AppUserRole? get role => _role;
  bool get isAuthenticated => _user != null;
  bool get isProfessional => _role == AppUserRole.professional;
  bool get isPatient => _role == AppUserRole.patient;
  bool get isAdmin => _role == AppUserRole.admin;

  SessionProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    
    if (user != null) {
      await executeAsync(
        () => _loadUserRole(user.uid),
        errorMessage: 'Error cargando rol de usuario',
      );
    } else {
      _role = null;
      setLoaded();
    }
  }

  Future<void> _loadUserRole(String uid) async {
    _role = await _roleService.getUserRole(uid);
  }

  Future<void> refreshUserRole() async {
    if (_user == null) return;
    
    await executeAsync(
      () async {
        _roleService.clearCache(_user!.uid);
        await _loadUserRole(_user!.uid);
      },
      errorMessage: 'Error refrescando rol de usuario',
    );
  }
}
