import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa los diferentes estados de la sesión.
/// Puedes extenderlo si deseas incluir más detalle (por ejemplo, mensajes de error).
enum SessionStatus {
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Modelo que agrupa el usuario actual, su rol y el estado de la sesión.
class UserSession {
  final User? user;
  final String role;
  final SessionStatus status;

  UserSession({
    this.user,
    required this.role,
    required this.status,
  });
}

/// Proveedor de estado para la sesión, basado en Riverpod StateNotifier.
final sessionProvider =
    StateNotifierProvider<SessionNotifier, UserSession>((ref) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<UserSession> {
  SessionNotifier()
      : super(
          UserSession(
            user: null,
            role: 'unknown',
            status: SessionStatus.unauthenticated,
          ),
        ) {
    _authStateChanges();
  }

  // Escucha los cambios de autenticación de Firebase.
  void _authStateChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        // No hay sesión activa
        state = UserSession(
          user: null,
          role: 'unknown',
          status: SessionStatus.unauthenticated,
        );
      } else {
        // Carga la información de la sesión
        await _loadUserSession(user);
      }
    });
  }

  /// Carga la sesión del usuario desde Firestore (obtiene el rol, etc.).
  Future<void> _loadUserSession(User user) async {
    try {
      // Pasamos a estado de carga
      state = UserSession(
        user: user,
        role: 'unknown',
        status: SessionStatus.loading,
      );

      final String role = await _getUserRole(user.uid);
      // Una vez obtenido el rol, actualizamos la sesión con el usuario, rol y estado autenticado
      state = UserSession(
        user: user,
        role: role,
        status: SessionStatus.authenticated,
      );

      print('Sesión iniciada: ${user.email}, Rol: $role');
    } catch (e) {
      print('Error obteniendo sesión: $e');
      // En caso de error, limpiamos la sesión y marcamos el estado
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.error,
      );
    }
  }

  /// Intenta obtener el rol del usuario en [patients] o [doctors].
  /// Incluye reintentos automáticos con un ligero retraso si hay error.
  Future<String> _getUserRole(String uid, {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final patientDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(uid)
            .get();
        if (patientDoc.exists) {
          return 'patient';
        }

        final doctorDoc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(uid)
            .get();
        if (doctorDoc.exists) {
          return 'professional';
        }

        // Si no se encontró en ninguna colección
        throw Exception('No se encontró documento con UID: $uid');
      } catch (e) {
        print('Error en reintento $attempt de _getUserRole: $e');
        // Esperar un poco antes de reintentar
        if (attempt < retries - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          // Si se agotaron reintentos, devolvemos unknown
          return 'unknown';
        }
      }
    }
    // Por seguridad, aunque en teoría nunca llegaría aquí
    return 'unknown';
  }

  /// Inicia sesión con email y contraseña.
  Future<void> logIn(String email, String password) async {
    try {
      // Indicamos estado de carga
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.loading,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserSession(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      print('Error de autenticación: ${e.message}');
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.error,
      );
    } catch (e) {
      print('Error al iniciar sesión: $e');
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.error,
      );
    }
  }

  /// Inicia sesión con Google.
  /// Aquí se asume que `user` ya fue obtenido tras una autenticación con Google.
  Future<void> logInWithGoogle(User user) async {
    try {
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.loading,
      );
      await _loadUserSession(user);
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.error,
      );
    }
  }

  /// Cierra sesión.
  Future<void> logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.unauthenticated,
      );
      print('Usuario deslogueado');
    } catch (e) {
      print('Error al cerrar sesión: $e');
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.error,
      );
    }
  }

  /// Recarga manualmente la sesión del usuario (si ya está autenticado).
  Future<void> reloadUserSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserSession(user);
    } else {
      // Si no hay usuario, marcamos estado como no autenticado
      state = UserSession(
        user: null,
        role: 'unknown',
        status: SessionStatus.unauthenticated,
      );
    }
  }
}
