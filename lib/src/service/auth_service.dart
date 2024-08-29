import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para iniciar sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      // Añadir usuario a Firestore si es un nuevo usuario
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(user?.uid).set({
          'email': user?.email,
          'role': 'patient', // o el rol que desees asignar por defecto
        });
      }
      return user;
    } catch (e) {
      print('Error en signInWithEmailAndPassword: $e');
      return null;
    }
  }

  // Método para iniciar sesión con Google utilizando FirebaseAuth
  Future<User?> signInWithGoogle() async {
    try {
      // Iniciar el flujo de autenticación de Google
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Puedes usar signInWithPopup o signInWithRedirect
      UserCredential result =
          await _firebaseAuth.signInWithPopup(googleProvider);
      // UserCredential result = await _firebaseAuth.signInWithRedirect(googleProvider);

      User? user = result.user;

      // Añadir usuario a Firestore si es un nuevo usuario
      if (result.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(user?.uid).set({
          'email': user?.email,
          'role': 'patient', // o el rol que desees asignar por defecto
        });
      }

      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Método para registrar con email y contraseña
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String role) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      // Añadir usuario a Firestore
      await _firestore.collection('users').doc(user?.uid).set({
        'email': user?.email,
        'role': role,
      });

      return user;
    } catch (e) {
      print('Error en registerWithEmailAndPassword: $e');
      return null;
    }
  }

  // Método para obtener el rol del usuario
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['role'] ?? 'unknown';
      } else {
        return 'unknown';
      }
    } catch (e) {
      print('Error en getUserRole: $e');
      return 'unknown';
    }
  }
}
