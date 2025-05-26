import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneN;
  final String dni;
  final String address;
  final String license;
  final String speciality;
  final DateTime? dob;
  final List<String> workDays;
  final String startTime;
  final String endTime;
  final int breakDuration;
  final bool profileCompleted;
  
  ProfessionalModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneN,
    required this.dni,
    required this.address,
    required this.license,
    required this.speciality,
    this.dob,
    required this.workDays,
    required this.startTime,
    required this.endTime,
    this.breakDuration = 15,
    this.profileCompleted = false,
  });
  
  // Create a model from Firestore data
  factory ProfessionalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle workDays field that might be named differently
    List<String> workDays = [];
    if (data['workDays'] != null) {
      workDays = List<String>.from(data['workDays']);
    }
    
    return ProfessionalModel(
      uid: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneN: data['phoneN'] ?? '',
      dni: data['dni'] ?? '',
      address: data['address'] ?? '',
      license: data['license'] ?? '',
      speciality: data['speciality'] ?? '',
      dob: data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
      workDays: workDays,
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
      breakDuration: data['breakDuration'] ?? 15,
      profileCompleted: data['profileCompleted'] ?? false,
    );
  }
  
  // Add this constructor to create a model from a plain Map
  factory ProfessionalModel.fromMap(Map<String, dynamic> data) {
    // Handle workDays field that might be named differently
    List<String> workDays = [];
    if (data['workDays'] != null) {
      workDays = List<String>.from(data['workDays']);
    }
    
    return ProfessionalModel(
      uid: data['uid'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneN: data['phoneN'] ?? '',
      dni: data['dni'] ?? '',
      address: data['address'] ?? '',
      license: data['license'] ?? '',
      speciality: data['speciality'] ?? '',
      dob: data['dob'] != null ? 
          (data['dob'] is Timestamp ? 
              (data['dob'] as Timestamp).toDate() : 
              data['dob'] as DateTime) : 
          null,
      workDays: workDays,
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
      breakDuration: data['breakDuration'] ?? 15,
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
      'address': address,
      'license': license,
      'speciality': speciality,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'workDays': workDays,
      'startTime': startTime,
      'endTime': endTime,
      'breakDuration': breakDuration,
      'profileCompleted': profileCompleted,
    };
  }
  
  // Create a copy with updated fields
  ProfessionalModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneN,
    String? dni,
    String? address,
    String? license,
    String? speciality,
    DateTime? dob,
    List<String>? workDays,
    String? startTime,
    String? endTime,
    int? breakDuration,
    bool? profileCompleted,
  }) {
    return ProfessionalModel(
      uid: this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneN: phoneN ?? this.phoneN,
      dni: dni ?? this.dni,
      address: address ?? this.address,
      license: license ?? this.license,
      speciality: speciality ?? this.speciality,
      dob: dob ?? this.dob,
      workDays: workDays ?? this.workDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakDuration: breakDuration ?? this.breakDuration,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }
  
  // Helper to get full name
  String get fullName => '$firstName $lastName'.trim();
}