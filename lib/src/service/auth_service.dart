import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      throw AuthException(message: 'Error al actualizar la información del profesional.');
    }
  }

  // Método para iniciar sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Manejo específico de errores de FirebaseAuth
      throw AuthException(code: e.code, message: e.message);
    } catch (e) {
      // Otros errores
      throw AuthException(message: 'Error desconocido al iniciar sesión.');
    }
  }

  // Método para registrar con email y contraseña
  Future<User?> registerWithEmailAndPassword(String email, String password, String role) async {
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
    } on FirebaseAuthException catch (e) {
      // Manejo específico de errores de FirebaseAuth
      throw AuthException(code: e.code, message: e.message);
    } catch (e) {
      // Otros errores
      throw AuthException(message: 'Error desconocido al registrar.');
    }
  }

  // Método para iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // Proceso para aplicaciones web
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // Proceso para dispositivos móviles
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          // El usuario canceló el inicio de sesión
          throw AuthException(message: 'Inicio de sesión cancelado.');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
            await _firebaseAuth.signInWithCredential(credential);
      }

      User? user = userCredential.user;

      // Añadir usuario a Firestore si es un nuevo usuario
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(user?.uid).set({
          'email': user?.email,
          'role': 'patient', // o el rol que desees asignar por defecto
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    } catch (e) {
      throw AuthException(message: 'Error desconocido al iniciar sesión con Google.');
    }
  }

  // Método para obtener el rol del usuario
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('role')) {
          return data['role'] as String;
        }
      }
      return 'unknown';
    } catch (e) {
      print('Error en getUserRole: $e');
      return 'unknown';
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // Realiza cualquier limpieza adicional si es necesario
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

