import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final sessionProvider =
    StateNotifierProvider<SessionNotifier, UserSession?>((ref) {
  return SessionNotifier();
});

class UserSession {
  final User user;
  final String role;

  UserSession({required this.user, required this.role});
}

class SessionNotifier extends StateNotifier<UserSession?> {
  SessionNotifier() : super(null) {
    _authStateChanges();
  }

  // Escuchar los cambios de autenticación desde Firebase
  void _authStateChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadUserSession(user);
      } else {
        print('No hay sesión activa');
        state = null;
      }
    });
  }

  // Función para cargar la sesión del usuario
  Future<void> _loadUserSession(User user) async {
    try {
      state = null; // Opción de indicar un estado de "cargando"
      final role = await _getUserRole(user.uid);
      state = UserSession(user: user, role: role);
      print('Sesión iniciada: ${user.email}, Rol: $role');
    } catch (e) {
      print('Error obteniendo el rol en _loadUserSession: $e');
      state = null; // Reiniciar el estado si hay un error
    }
  }

  // Función para obtener el rol del usuario desde Firestore
  Future<String> _getUserRole(String uid, {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final role = data['role'];
          if (role != null && role is String) {
            print('Rol obtenido: $role');
            return role;
          } else {
            throw Exception(
                'El campo role no está definido o es inválido en Firestore. Datos del documento: $data');
          }
        } else {
          throw Exception(
              'Documento de usuario no encontrado en Firestore. UID: $uid');
        }
      } catch (e) {
        print('Error obteniendo el rol del usuario en intento $attempt: $e');
        if (attempt < retries - 1) {
          // Esperar antes de volver a intentar
          await Future.delayed(Duration(milliseconds: 500));
        } else {
          return 'unknown'; // Si se agotan los intentos, devuelve el valor predeterminado
        }
      }
    }
    return 'unknown';
  }

  // Función para iniciar sesión con email y password
  Future<void> logIn(String email, String password) async {
    try {
      state = null; // Estado de "cargando"
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserSession(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      print('Error de autenticación: ${e.message}');
      state = null;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      state = null;
    }
  }

  // Función para iniciar sesión con Google
  Future<void> logInWithGoogle(User user) async {
    try {
      state = null; // Estado de "cargando"
      await _loadUserSession(user);
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
      state = null;
    }
  }

  // Función para cerrar sesión
  Future<void> logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      state = null;
      print('Usuario deslogueado');
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Función para recargar la sesión del usuario
  Future<void> reloadUserSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserSession(user);
    }
  }
}
