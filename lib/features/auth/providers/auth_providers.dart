import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

/// Estados que representan el flujo de autenticación
enum AuthStatus {
  /// Estado inicial cuando la app se inicia
  initial,
  
  /// Autenticación en progreso
  loading,
  
  /// Usuario autenticado
  authenticated,
  
  /// Usuario no autenticado
  unauthenticated,
  
  /// Error durante la autenticación
  error,
}

/// Modelo que representa el estado actual de autenticación
class AuthState {
  final User? user;
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.user,
    required this.status,
    this.errorMessage,
  });

  /// Crea una copia del estado actual con los campos especificados reemplazados
  AuthState copyWith({
    User? user,
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  String toString() => 'AuthState(status: $status, user: ${user?.email}, error: $errorMessage)';
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

/// Controlador que gestiona el estado de autenticación
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService)
      : super(const AuthState(status: AuthStatus.initial)) {
    _initializeAuthListener();
  }

  /// Configura un listener para cambios de estado de autenticación de Firebase
  void _initializeAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        state = state.copyWith(
          user: null,
          status: AuthStatus.unauthenticated,
        );
      } else {
        await _authenticateUser(firebaseUser);
      }
    });
  }

  /// Actualiza el estado cuando un usuario se autentica
  Future<void> _authenticateUser(User user) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      
      // Cargar datos adicionales del usuario si es necesario
      // Por ejemplo, podrías obtener datos del perfil del usuario de Firestore
      
      state = state.copyWith(
        user: user,
        status: AuthStatus.authenticated,
        errorMessage: null,
      );
      
      debugPrint('Sesión cargada: ${user.email}');
    } catch (e) {
      debugPrint('Error autenticando usuario: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error autenticando usuario: $e',
      );
    }
  }

  /// Inicia sesión con email y contraseña
  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      
      // Llama al método signInWithEmail con los parámetros posicionales
      final user = await _authService.signInWithEmail(email, password);
      
      if (user != null) {
        await _authenticateUser(user);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Inicio de sesión fallido',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Registra un nuevo usuario con email y contraseña
  Future<void> registerWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String dni,
    required String password,
    required String phoneN,
    String? dob,
    // Campos específicos para doctores
    String? license,
    String? speciality,
    String? startTime,
    String? endTime,
    List<String>? workDays,
    String? breakDuration,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      
      // Determine role based on presence of doctor-specific fields
      final String role = (license != null && speciality != null) ? 'doctor' : 'patient';
      
      // Register with basic email auth - sin el parámetro role
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
      );
      
      if (user != null) {
        // Crear documento en la colección correspondiente después de autenticar
        await _createUserDocument(
          user: user,
          firstName: firstName,
          lastName: lastName,
          email: email,
          dni: dni,
          phoneN: phoneN,
          dob: dob,
          role: role,
          license: license,
          speciality: speciality,
          startTime: startTime,
          endTime: endTime,
          workDays: workDays,
          breakDuration: breakDuration,
        );
        
        await _authenticateUser(user);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Registro fallido',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Crea el documento del usuario en la colección correspondiente
  Future<void> _createUserDocument({
    required User user,
    required String firstName,
    required String lastName,
    required String email,
    required String dni,
    required String phoneN,
    required String role,
    String? dob,
    String? license,
    String? speciality,
    String? startTime,
    String? endTime,
    List<String>? workDays,
    String? breakDuration,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Datos básicos comunes a todos los usuarios
      Map<String, dynamic> userData = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'dni': dni,
        'phoneN': phoneN,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Añadir fecha de nacimiento si está disponible
      if (dob != null) {
        userData['dob'] = dob;
      }
      
      // Determinar la colección basada en el rol
      String collection;
      if (role == 'doctor') {
        collection = 'doctors';
        
        // Añadir campos específicos de doctor
        if (license != null) userData['license'] = license;
        if (speciality != null) userData['speciality'] = speciality;
        if (startTime != null) userData['startTime'] = startTime;
        if (endTime != null) userData['endTime'] = endTime;
        if (breakDuration != null) userData['breakDuration'] = breakDuration;
        
        // Añadir días laborables
        if (workDays != null && workDays.isNotEmpty) {
          userData['workDays'] = workDays;
        }
      } else {
        collection = 'patients';
      }
      
      // Crear documento en Firestore
      await firestore.collection(collection).doc(user.uid).set(userData);
      
      // Actualizar nombre de usuario en Firebase Auth
      await user.updateDisplayName('$firstName $lastName');
    } catch (e) {
      debugPrint('Error creando documento de usuario: $e');
      throw Exception('Error al crear el perfil de usuario: $e');
    }
  }

  /// Inicia sesión con Google
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _authenticateUser(user);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Inicio de sesión con Google fallido',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = state.copyWith(
        user: null,
        status: AuthStatus.unauthenticated,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Recarga la sesión actual
  Future<void> reloadSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _authenticateUser(user);
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
      );
    }
  }
}

/// Proveedor para el controlador de autenticación
final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});