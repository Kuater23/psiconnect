import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna el usuario autenticado actual, o null si no hay ninguno.
  User? getCurrentUser() => _firebaseAuth.currentUser;

  /// Verifica si el usuario existe en Firestore en alguna de las colecciones 'patients' o 'doctors'.
  Future<bool> _userExists(String uid) async {
    final patientDoc = await _firestore.collection('patients').doc(uid).get();
    final doctorDoc = await _firestore.collection('doctors').doc(uid).get();
    return patientDoc.exists || doctorDoc.exists;
  }

  /// Obtiene el rol del usuario buscando en las colecciones 'patients' y 'doctors'.
  Future<String> getUserRole(String uid) async {
    try {
      final patientDoc = await _firestore.collection('patients').doc(uid).get();
      if (patientDoc.exists) return 'patient';

      final doctorDoc = await _firestore.collection('doctors').doc(uid).get();
      if (doctorDoc.exists) return 'professional';

      return 'unknown';
    } catch (e) {
      print('Error al obtener el rol del usuario: $e');
      return 'unknown';
    }
  }

  /// Inicia sesión con email y contraseña.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
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

  /// Actualiza el rol del usuario, moviendo su documento entre colecciones si es necesario.
  Future<void> updateUserRole(String uid, String role) async {
    try {
      final currentRole = await getUserRole(uid);
      if (currentRole == role) return;

      // Determinar la colección antigua y la nueva.
      final String oldCollection = currentRole == 'professional' ? 'doctors' : 'patients';
      final String newCollection = role == 'professional' ? 'doctors' : 'patients';

      final oldDocSnapshot = await _firestore.collection(oldCollection).doc(uid).get();
      if (oldDocSnapshot.exists) {
        // Se obtiene la data actual, se elimina el documento antiguo y se crea uno nuevo con el rol actualizado.
        final userData = oldDocSnapshot.data()!;
        await _firestore.collection(oldCollection).doc(uid).delete();
        userData['role'] = role;
        await _firestore.collection(newCollection).doc(uid).set(userData);
      } else {
        throw AuthException(
          code: 'user-not-found',
          message: 'No se encontró el usuario para actualizar el rol.',
        );
      }
    } catch (e) {
      throw AuthException(
        code: 'update-role-error',
        message: 'Error al actualizar el rol del usuario: $e',
      );
    }
  }

  /// Registra un usuario con email y contraseña, y crea su documento en Firestore.
  /// Para usuarios profesionales se guardan campos adicionales.
  Future<User?> registerWithEmailAndPassword({
    required String name,
    required String lastName,
    required String email,
    required String dni,
    required String password,
    required String role,
    String? n_matricula,
    String? specialty,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      // Si el usuario es nuevo y no existe en Firestore, se crea el documento.
      if (user != null && !(await _userExists(user.uid))) {
        final String collection = role == 'professional' ? 'doctors' : 'patients';
        Map<String, dynamic> userData = {
          'firstName': name,
          'lastName': lastName,
          'email': user.email,
          'dni': dni,
          'role': role,
        };

        if (role == 'professional') {
          userData['n_matricula'] = n_matricula;
          userData['specialty'] = specialty;
        }

        await _firestore.collection(collection).doc(user.uid).set(userData);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    } catch (e) {
      throw AuthException(message: 'Error desconocido al registrar.');
    }
  }

  /// Inicia sesión con Google.
  /// En web se utiliza [signInWithPopup] y en móvil se utiliza [GoogleSignIn].
  Future<User?> signInWithGoogle({required String role}) async {
  try {
    UserCredential userCredential;
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
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

    // Verificamos si es un usuario completamente nuevo
    final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (user != null && isNewUser) {
      // Si no nos pasaron un 'role' válido => NO creamos doc, lanzamos excepción
      if (role.isEmpty) {
        // Este caso indica que vino de la pantalla de Login sin un rol, o no queremos crear doc
        // Forzamos que se registre en la pantalla adecuada
        // Cerrar la sesión que acabamos de crear para no dejar al usuario "loggeado"
        await _firebaseAuth.signOut();

        throw AuthException(
          code: 'user-new-no-registration',
          message: 'No tienes una cuenta registrada. Por favor regístrate primero.',
        );
      } else {
        // Caso normal: si hay un role => creamos el documento en Firestore
        final String collection = role == 'professional' ? 'doctors' : 'patients';
        await _firestore.collection(collection).doc(user.uid).set({
          'email': user.email,
          'role': role,
          'name': user.displayName,
        });
      }
    }

    return user;
  } on FirebaseAuthException catch (e) {
    throw AuthException(code: e.code, message: e.message);
  } catch (e) {
    throw AuthException(message: 'Error desconocido al iniciar sesión con Google.');
  }
}

  /// Cierra la sesión del usuario.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error en signOut: $e');
    }
  }
}

/// Excepción personalizada para errores de autenticación.
class AuthException implements Exception {
  final String? code;
  final String? message;

  AuthException({this.code, this.message});

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}
