// lib/features/auth/services/auth_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/error_logger.dart';
import '../../../core/services/user_role_service.dart';

enum UserRole { patient, professional }

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _roleService = UserRoleService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ==================== Google Sign-In ====================
  
  Future<UserCredential> _googleWeb() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});
    return _auth.signInWithPopup(provider);
  }

  Future<UserCredential> _googleMobile() async {
    final user = await GoogleSignIn().signIn();
    if (user == null) {
      throw Exception('Google sign-in cancelado por el usuario');
    }
    final auth = await user.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Sign-in con Google y creación idempotente de perfil
  Future<({User user, String role})> signInWithGoogleEnsureProfile({
    UserRole? desiredRole,
  }) async {
    try {
      final cred = kIsWeb ? await _googleWeb() : await _googleMobile();
      final user = cred.user!;
      
      final role = await _ensureUserProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        desiredRole: desiredRole,
      );
      
      return (user: user, role: role);
    } catch (e, st) {
      ErrorLogger.logError('Error en signInWithGoogleEnsureProfile', e, st);
      rethrow;
    }
  }

  Future<String> _ensureUserProfile({
    required String uid,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? desiredRole,
  }) async {
    // Usar el servicio centralizado de roles
    final currentRole = await _roleService.getUserRole(uid);
    
    if (currentRole == AppUserRole.professional) return 'professional';
    if (currentRole == AppUserRole.patient) return 'patient';
    if (currentRole == AppUserRole.admin) return 'admin';

    // No existe perfil
    if (desiredRole == null) return 'unknown';

    final baseData = {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    };

    try {
      if (desiredRole == UserRole.professional) {
        await _db.collection('doctors').doc(uid).set(baseData, SetOptions(merge: true));
        _roleService.clearCache(uid); // Limpiar caché después de crear
        return 'professional';
      } else {
        await _db.collection('patients').doc(uid).set(baseData, SetOptions(merge: true));
        _roleService.clearCache(uid);
        return 'patient';
      }
    } catch (e, st) {
      ErrorLogger.logError('Error creando perfil de usuario', e, st);
      rethrow;
    }
  }

  // ==================== Email/Password ====================
  
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e, st) {
      ErrorLogger.logError('Error en signInWithEmailPassword', e, st);
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailPassword(
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _ensureUserProfile(
        uid: cred.user!.uid,
        email: email,
        desiredRole: role,
      );
      
      return cred;
    } catch (e, st) {
      ErrorLogger.logError('Error en createUserWithEmailPassword', e, st);
      rethrow;
    }
  }

  // ==================== Sign Out ====================
  
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        if (!kIsWeb) GoogleSignIn().signOut(),
      ]);
      _roleService.clearCache(); // Limpiar todo el caché al salir
    } catch (e, st) {
      ErrorLogger.logError('Error en signOut', e, st);
      rethrow;
    }
  }

  // ==================== Password Reset ====================
  
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, st) {
      ErrorLogger.logError('Error enviando email de recuperación', e, st);
      rethrow;
    }
  }
}