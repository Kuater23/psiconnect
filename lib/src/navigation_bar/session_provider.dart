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

  void _authStateChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        final role = await _getUserRole(user.uid);
        state = UserSession(user: user, role: role);
      } else {
        state = null;
      }
    });
  }

  Future<String> _getUserRole(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      print('Documento de usuario encontrado: ${doc.data()}'); // Imprime el contenido del documento
      final role = doc.data()!['role'];
      if (role != null) {
        return role as String;
      } else {
        throw 'El campo role no está definido';
      }
    } else {
      throw 'Documento de usuario no encontrado';
    }
  } catch (e) {
    print('Error obteniendo el rol del usuario: $e');
    return 'unknown'; // Valor predeterminado para detectar problemas
  }
  }

  Future<void> logIn(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final role = await _getUserRole(userCredential.user!.uid);
      state = UserSession(user: userCredential.user!, role: role);
    } catch (e) {
      print('Error al iniciar sesión: $e');
      state = null;
    }
  }

  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    state = null;
  }
}
