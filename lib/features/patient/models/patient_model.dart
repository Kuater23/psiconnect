import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneN;
  final String dni;
  final DateTime? dob;
  final bool profileCompleted;
  
  PatientModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneN,
    required this.dni,
    this.dob,
    this.profileCompleted = false,
  });
  
  // Create a model from Firestore data
  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PatientModel(
      uid: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneN: data['phoneN'] ?? '',
      dni: data['dni'] ?? '',
      dob: data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
      profileCompleted: data['profileCompleted'] ?? false,
    );
  }
  
  // Add a method to create a model from a regular Map
  factory PatientModel.fromMap(Map<String, dynamic> data) {
    return PatientModel(
      uid: data['uid'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneN: data['phoneN'] ?? '',
      dni: data['dni'] ?? '',
      dob: data['dob'] != null ? 
          (data['dob'] is Timestamp ? 
              (data['dob'] as Timestamp).toDate() : 
              data['dob'] as DateTime) : 
          null,
      profileCompleted: data['profileCompleted'] ?? false,
    );
  }
  
  // Convert model to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneN': phoneN,
      'dni': dni,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'profileCompleted': profileCompleted,
    };
  }
  
  // Create a copy with updated fields
  PatientModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneN,
    String? dni,
    DateTime? dob,
    bool? profileCompleted,
  }) {
    return PatientModel(
      uid: this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneN: phoneN ?? this.phoneN,
      dni: dni ?? this.dni,
      dob: dob ?? this.dob,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }
  
  // Helper to get full name
  String get fullName => '$firstName $lastName'.trim();
}