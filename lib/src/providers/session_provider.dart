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
        try {
          state = null; // Opción de indicar un estado de "cargando"
          final role = await _getUserRole(user.uid);
          state = UserSession(user: user, role: role);
          print('Sesión iniciada: ${user.email}, Rol: $role');
        } catch (e) {
          print('Error obteniendo el rol en authStateChanges: $e');
          state = null; // Reiniciar el estado si hay un error
        }
      } else {
        print('No hay sesión activa');
        state = null;
      }
    });
  }

  // Función para obtener el rol del usuario desde Firestore
  Future<String> _getUserRole(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final role = doc.data()!['role'];
        if (role != null && role is String) {
          print('Rol obtenido: $role');
          return role;
        } else {
          throw Exception(
              'El campo role no está definido o es inválido en Firestore');
        }
      } else {
        throw Exception('Documento de usuario no encontrado en Firestore');
      }
    } catch (e) {
      print('Error obteniendo el rol del usuario: $e');
      return 'unknown'; // Devolver un valor por defecto en caso de error
    }
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
      final role = await _getUserRole(userCredential.user!.uid);
      state = UserSession(user: userCredential.user!, role: role);
      print('Usuario logueado: ${userCredential.user!.email}, Rol: $role');
    } on FirebaseAuthException catch (e) {
      print('Error de autenticación: ${e.message}');
      state = null;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      state = null;
    } finally {
      // Puedes agregar algún ajuste adicional si es necesario aquí
    }
  }

  // Función para iniciar sesión con Google
  Future<void> logInWithGoogle(User user) async {
    try {
      state = null; // Estado de "cargando"
      final role = await _getUserRole(user.uid);
      state = UserSession(user: user, role: role);
      print('Usuario logueado con Google: ${user.email}, Rol: $role');
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
      state = null;
    } finally {
      // Manejar el final del proceso
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
}
