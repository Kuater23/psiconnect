import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'professional_provider.dart';

/// Estados posibles de autenticación.
enum AuthStatus { authenticated, unauthenticated, loading, error }

/// Notifier que maneja la autenticación utilizando [AuthService] y Riverpod.
class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthService _authService;
  final Ref ref;
  String? _errorMessage;

  AuthNotifier(this._authService, this.ref)
      : super(AuthStatus.unauthenticated);

  /// Getter para el mensaje de error.
  String? get errorMessage => _errorMessage;

  /// Establece el estado a "loading" y resetea el mensaje de error.
  void _setLoading() {
    state = AuthStatus.loading;
    _errorMessage = null;
  }

  /// Establece el estado a "authenticated".
  void _setAuthenticated() {
    state = AuthStatus.authenticated;
  }

  /// Establece el estado a "unauthenticated".
  void _setUnauthenticated() {
    state = AuthStatus.unauthenticated;
  }

  /// Establece el estado a "error" y asigna el mensaje proporcionado.
  void _setError(String message) {
    state = AuthStatus.error;
    _errorMessage = message;
  }

  /// Verifica el estado de autenticación actual.
  Future<void> checkAuthStatus() async {
    try {
      final user = _authService.getCurrentUser();
      state =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    } catch (e) {
      _setError('Error al verificar el estado de autenticación');
    }
  }

  /// Retorna el usuario actual de Firebase.
  User? getCurrentUser() => _authService.getCurrentUser();

  /// Actualiza el rol del usuario en la base de datos.
  Future<void> updateRole(String uid, String role) async {
    _setLoading();
    try {
      await _authService.updateUserRole(uid, role);
      _setAuthenticated();
    } catch (e) {
      _setError('Error al actualizar el rol del usuario');
    }
  }

  /// Inicia sesión utilizando email y contraseña.
  Future<void> signInWithEmail(String email, String password) async {
    _setLoading();
    try {
      final user =
          await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        await ref.read(professionalProvider.notifier).reinitialize();
        _setAuthenticated();
      } else {
        _setUnauthenticated();
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Error al iniciar sesión');
    } catch (e) {
      _setError('Error desconocido al iniciar sesión');
    }
  }

  /// Registra un usuario utilizando email y contraseña junto con datos adicionales.
  Future<void> registerWithEmail({
    required String name,
    required String lastName,
    required String email,
    required String dni,
    required String password,
    required String role,
    String? n_matricula,
  }) async {
    _setLoading();
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
        await ref.read(professionalProvider.notifier).reinitialize();
        _setAuthenticated();
      } else {
        _setUnauthenticated();
      }
    } on AuthException catch (e) {
      _setError(e.message);
      print('AuthException: ${e.code} - ${e.message}');
    } catch (e) {
      _setError('Error desconocido al registrar');
      print('Exception: $e');
    }
  }

  /// Cierra la sesión del usuario.
  Future<void> signOut() async {
    _setLoading();
    try {
      await _authService.signOut();
      ref.read(professionalProvider.notifier).resetState();
      _setUnauthenticated();
    } catch (e) {
      _setError('Error al cerrar sesión');
    }
  }

  /// Inicia sesión utilizando Google.
  Future<void> signInWithGoogle({required String role}) async {
    _setLoading();
    try {
      final user = await _authService.signInWithGoogle(role: role);
      if (user != null) {
        await ref.read(professionalProvider.notifier).reinitialize();
        _setAuthenticated();
      } else {
        _setUnauthenticated();
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Error al iniciar sesión con Google');
    } catch (e) {
      _setError('Error desconocido al iniciar sesión con Google');
    }
  }
}

// ---------------- Provider Definitions ----------------

/// Proveedor de la instancia de [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Proveedor del [AuthNotifier] que expone el estado de autenticación.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

/// Clase de excepción personalizada para la autenticación.
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);
}
