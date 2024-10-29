import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para obtener el usuario autenticado actual
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Helper para verificar si el usuario ya existe en Firestore
  Future<bool> _userExists(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.exists;
  }

  // Método para actualizar el rol del usuario
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': FirebaseAuth.instance.currentUser?.email,
        'role': role,
      }, SetOptions(merge: true));
    } catch (e) {
      throw AuthException(message: 'Error al actualizar el rol del usuario.');
    }
  }

  // Método para actualizar información adicional del profesional
  Future<void> updateProfessionalInfo({
    required String uid,
    required String documentType,
    required String idNumber,
    required String matricula,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'documentType': documentType,
        'idNumber': idNumber,
        'matricula': matricula,
      }, SetOptions(merge: true));
    } catch (e) {
      throw AuthException(
          message: 'Error al actualizar la información del profesional.');
    }
  }

  // Método para iniciar sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    } catch (e) {
      throw AuthException(message: 'Error desconocido al iniciar sesión.');
    }
  }

  // Método para registrar con email y contraseña
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
    String? documentType,
    String? documentNumber,
    String? nroMatricula,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null && !(await _userExists(user.uid))) {
        // Solo crear el documento si no existe
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': role,
          'documentType': documentType,
          'documentNumber': documentNumber,
          'n_matricula': nroMatricula,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    } catch (e) {
      throw AuthException(message: 'Error desconocido al registrar.');
    }
  }

  // Método para iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          throw AuthException(message: 'Inicio de sesión cancelado.');
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      final user = userCredential.user;

      if (user != null &&
          (userCredential.additionalUserInfo?.isNewUser ?? false)) {
        if (!(await _userExists(user.uid))) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'role': 'patient', // Rol por defecto
          });
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    } catch (e) {
      throw AuthException(
          message: 'Error desconocido al iniciar sesión con Google.');
    }
  }

  // Método para obtener el rol del usuario
  Future<String> getUserRole(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();
      return data != null && data.containsKey('role')
          ? data['role'] as String
          : 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error en signOut: $e');
    }
  }
}

// Clase personalizada para excepciones de autenticación
class AuthException implements Exception {
  final String? code;
  final String? message;

  AuthException({this.code, this.message});

  @override
  String toString() {
    return 'AuthException(code: $code, message: $message)';
  }
}
