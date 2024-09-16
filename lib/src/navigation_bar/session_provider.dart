import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, UserSession?>((ref) {
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final role = doc.data()!['role'];
        if (role != null) {
          print('Rol obtenido: $role'); // Confirmar que el rol fue recuperado
          return role as String;
        } else {
          throw 'El campo role no está definido en Firestore';
        }
      } else {
        throw 'Documento de usuario no encontrado en Firestore';
      }
    } catch (e) {
      print('Error obteniendo el rol del usuario: $e');
      return 'unknown'; // Devolver un valor por defecto en caso de error
    }
  }

  // Función para iniciar sesión con email y password
  Future<void> logIn(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final role = await _getUserRole(userCredential.user!.uid);
      state = UserSession(user: userCredential.user!, role: role);
      print('Usuario logueado: ${userCredential.user!.email}, Rol: $role');
    } catch (e) {
      print('Error al iniciar sesión: $e');
      state = null;
    }
  }

  // Función para iniciar sesión con Google
  Future<void> logInWithGoogle(User user) async {
    try {
      final role = await _getUserRole(user.uid);
      state = UserSession(user: user, role: role);
      print('Usuario logueado con Google: ${user.email}, Rol: $role');
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
}
