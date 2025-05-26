// lib/features/auth/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/core/exceptions/app_exception.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

/// Service for handling authentication related functionality
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  AuthService(this._auth);

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Convertir el error de Firebase a un error más amigable
      switch (e.code) {
        case 'user-not-found':
          throw AuthException('No se encontró ningún usuario con este correo electrónico');
        case 'wrong-password':
          throw AuthException('Contraseña incorrecta');
        case 'user-disabled':
          throw AuthException('Esta cuenta ha sido deshabilitada');
        case 'too-many-requests':
          throw AuthException('Demasiados intentos fallidos. Por favor, intente más tarde');
        default:
          throw AuthException('Error al iniciar sesión: ${e.message}');
      }
    } catch (e) {
      throw AuthException('Error al iniciar sesión: $e');
    }
  }

  /// Register with email and password
  Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Convertir el error de Firebase a un error más amigable
      switch (e.code) {
        case 'email-already-in-use':
          throw AuthException('Este correo electrónico ya está registrado');
        case 'weak-password':
          throw AuthException('La contraseña es demasiado débil');
        case 'invalid-email':
          throw AuthException('El formato del correo electrónico es inválido');
        default:
          throw AuthException('Error al registrarse: ${e.message}');
      }
    } catch (e) {
      throw AuthException('Error al registrarse: $e');
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        // Web-specific Google sign-in
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile specific Google sign-in
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw AuthException('Inicio de sesión con Google cancelado por el usuario');
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        // Simplemente devuelve el usuario, la verificación de existencia
        // se hará en el SessionProvider
        return user;
      }
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }
}