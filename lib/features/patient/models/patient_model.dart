import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/base_model.dart';

class PatientModel extends BaseModel {
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? firstName;
  final String? lastName;
  final String? phoneN;
  final String? dni;
  final DateTime? birthDate;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? medications;
  final String? status;
  final bool profileCompleted;  // ✅ RESTAURADO

  PatientModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.email,
    this.displayName,
    this.photoURL,
    this.firstName,
    this.lastName,
    this.phoneN,
    this.dni,
    this.birthDate,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    this.bloodType,
    this.allergies,
    this.medications,
    this.status,
    this.profileCompleted = false,  // ✅ Default false
  });

  factory PatientModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento sin datos');
    }

    return PatientModel(
      id: doc.id,
      createdAt: BaseModel.timestampToDateTime(data['createdAt']),
      updatedAt: BaseModel.timestampToDateTime(data['updatedAt']),
      email: BaseModel.safeString(data['email']),
      displayName: BaseModel.safeString(data['displayName']),
      photoURL: BaseModel.safeString(data['photoURL']),
      firstName: BaseModel.safeString(data['firstName']),
      lastName: BaseModel.safeString(data['lastName']),
      phoneN: BaseModel.safeString(data['phoneN']),
      dni: BaseModel.safeString(data['dni']),
      birthDate: BaseModel.timestampToDateTime(data['birthDate']),
      address: BaseModel.safeString(data['address']),
      emergencyContact: BaseModel.safeString(data['emergencyContact']),
      emergencyPhone: BaseModel.safeString(data['emergencyPhone']),
      bloodType: BaseModel.safeString(data['bloodType']),
      allergies: BaseModel.safeList<String>(data['allergies']),
      medications: BaseModel.safeList<String>(data['medications']),
      status: BaseModel.safeString(data['status']) ?? 'active',
      profileCompleted: data['profileCompleted'] ?? false,  // ✅ RESTAURADO
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...baseMap,
      if (email != null) 'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneN != null) 'phoneN': phoneN,
      if (dni != null) 'dni': dni,
      if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
      if (address != null) 'address': address,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
      if (bloodType != null) 'bloodType': bloodType,
      if (allergies != null) 'allergies': allergies,
      if (medications != null) 'medications': medications,
      'status': status ?? 'active',
      'profileCompleted': profileCompleted,  // ✅ RESTAURADO
    };
  }

  PatientModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    String? displayName,
    String? photoURL,
    String? firstName,
    String? lastName,
    String? phoneN,
    String? dni,
    DateTime? birthDate,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    String? bloodType,
    List<String>? allergies,
    List<String>? medications,
    String? status,
    bool? profileCompleted,  // ✅ RESTAURADO
  }) {
    return PatientModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneN: phoneN ?? this.phoneN,
      dni: dni ?? this.dni,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      status: status ?? this.status,
      profileCompleted: profileCompleted ?? this.profileCompleted,  // ✅ RESTAURADO
    );
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // ✅ NUEVO: Helper para verificar si el perfil está completo
  bool get isProfileComplete {
    return (firstName?.isNotEmpty ?? false) &&
           (lastName?.isNotEmpty ?? false) &&
           (phoneN?.isNotEmpty ?? false) &&
           (dni?.isNotEmpty ?? false) &&
           birthDate != null;
  }
}