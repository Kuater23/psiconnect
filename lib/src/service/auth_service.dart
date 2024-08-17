import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Asignar rol después de registrar al usuario
      await addUserToFirestore(userCredential.user!, 'viewer');
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> addUserToFirestore(User user, String role) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': role,
    });
  }
}
