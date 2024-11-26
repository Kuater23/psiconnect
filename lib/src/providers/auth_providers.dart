import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'professional_provider.dart'; // Import the professional provider

// Definimos los posibles estados de autenticación
enum AuthStatus { authenticated, unauthenticated, loading, error }

// Clase que manejará el estado de autenticación
class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthService _authService;
  final Ref ref; // Add a reference to the provider container
  String? _errorMessage;

  AuthNotifier(this._authService, this.ref) : super(AuthStatus.unauthenticated);

  // Método para obtener el mensaje de error (opcional para mostrar en UI)
  String? get errorMessage => _errorMessage;

  // Método para verificar si el usuario está autenticado (sesión persistente)
  Future<void> checkAuthStatus() async {
    try {
      final user = _authService
          .getCurrentUser(); // Verifica si hay un usuario autenticado
      if (user != null) {
        state = AuthStatus.authenticated;
      } else {
        state = AuthStatus.unauthenticated;
      }
    } catch (e) {
      state = AuthStatus.error;
      _errorMessage = 'Error al verificar el estado de autenticación';
    }
  }

  // Método para obtener el usuario actual
  User? getCurrentUser() {
    return _authService.getCurrentUser();
  }

  // Método para actualizar el rol del usuario
  Future<void> updateRole(String uid, String role) async {
    state = AuthStatus.loading;
    _errorMessage = null;
    try {
      await _authService.updateUserRole(uid, role);
      state = AuthStatus.authenticated;
    } catch (e) {
      state = AuthStatus.error;
      _errorMessage = 'Error al actualizar el rol del usuario';
    }
  }

  // Método para iniciar sesión con email y contraseña
  Future<void> signInWithEmail(String email, String password) async {
    state = AuthStatus.loading;
    _errorMessage = null;
    try {
      final user =
          await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        await ref
            .read(professionalProvider.notifier)
            .reinitialize(); // Reinitialize professional state
        state = AuthStatus.authenticated;
      } else {
        state = AuthStatus.unauthenticated;
      }
    } on FirebaseAuthException catch (e) {
      state = AuthStatus.error;
      _errorMessage =
          e.message; // Guardamos el mensaje de error específico de Firebase
    } catch (e) {
      state = AuthStatus.error;
      _errorMessage = 'Error desconocido al iniciar sesión';
    }
  }

  // Método para registrar un nuevo usuario
  Future<void> registerWithEmail({
    required String name,
    required String lastName,
    required String email,
    required String dni,
    required String password,
    required String role,
    String? n_matricula,
  }) async {
    state = AuthStatus.loading;
    _errorMessage = null;
    try {
      final user = await _authService.registerWithEmailAndPassword(
        name: name,
        lastName: lastName,
        email: email,
        dni: dni,
        password: password,
        role: role,
        n_matricula: n_matricula,
      );
      if (user != null) {
        await ref
            .read(professionalProvider.notifier)
            .reinitialize(); // Reinitialize professional state
        state = AuthStatus.authenticated;
      } else {
        state = AuthStatus.unauthenticated;
      }
    } on AuthException catch (e) {
      state = AuthStatus.error;
      _errorMessage = e.message; // Guardamos el mensaje de error específico
      print('AuthException: ${e.code} - ${e.message}');
    } catch (e) {
      state = AuthStatus.error;
      _errorMessage = 'Error desconocido al registrar';
      print('Exception: $e');
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    state = AuthStatus.loading;
    _errorMessage = null;
    try {
      await _authService.signOut();
      ref
          .read(professionalProvider.notifier)
          .resetState(); // Reset professional state
      state = AuthStatus.unauthenticated;
    } catch (e) {
      state = AuthStatus.error;
      _errorMessage = 'Error al cerrar sesión';
    }
  }

  // Método para iniciar sesión con Google
  Future<void> signInWithGoogle() async {
    state = AuthStatus.loading;
    _errorMessage = null;
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await ref
            .read(professionalProvider.notifier)
            .reinitialize(); // Reinitialize professional state
        state = AuthStatus.authenticated;
      } else {
        state = AuthStatus.unauthenticated;
      }
    } on FirebaseAuthException catch (e) {
      state = AuthStatus.error;
      _errorMessage =
          e.message; // Guardamos el mensaje de error específico de Firebase
    } catch (e) {
      state = AuthStatus.error;
      _errorMessage = 'Error desconocido al iniciar sesión con Google';
    }
  }
}

// Proveedor de estado de autenticación usando Riverpod
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  final authService = AuthService();
  return AuthNotifier(authService, ref);
});
