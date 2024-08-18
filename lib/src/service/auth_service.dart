import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para registrar un nuevo usuario
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      // Añadir usuario a Firestore
      await _firestore.collection('users').doc(user?.uid).set({
        'email': email,
        'role': 'patient', // o el rol que desees asignar por defecto
      });
      return user;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Método para iniciar sesión
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Método para obtener el rol del usuario
  Future<String?> getUserRole(User user) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        return data['role'] as String?;
      } else {
        print('No such document!');
        return null;
      }
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
}