import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/base_model.dart';

class ProfessionalModel extends BaseModel {
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? firstName;
  final String? lastName;
  final String? phoneN;
  final String? dni;
  final DateTime? birthDate;
  final String? speciality;
  final String? licenseNumber;
  final String? bio;
  final List<String>? certifications;
  final String? consultingAddress;
  final Map<String, dynamic>? availability;
  final double? consultationFee;
  final String? status;
  final bool profileCompleted;  // ✅ RESTAURADO

  ProfessionalModel({
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
    this.speciality,
    this.licenseNumber,
    this.bio,
    this.certifications,
    this.consultingAddress,
    this.availability,
    this.consultationFee,
    this.status,
    this.profileCompleted = false,  // ✅ Default false
  });

  factory ProfessionalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento sin datos');
    }

    return ProfessionalModel(
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
      speciality: BaseModel.safeString(data['speciality']),
      licenseNumber: BaseModel.safeString(data['licenseNumber']),
      bio: BaseModel.safeString(data['bio']),
      certifications: BaseModel.safeList<String>(data['certifications']),
      consultingAddress: BaseModel.safeString(data['consultingAddress']),
      availability: BaseModel.safeMap(data['availability']),
      consultationFee: BaseModel.safeDouble(data['consultationFee']),
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
      if (speciality != null) 'speciality': speciality,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (bio != null) 'bio': bio,
      if (certifications != null) 'certifications': certifications,
      if (consultingAddress != null) 'consultingAddress': consultingAddress,
      if (availability != null) 'availability': availability,
      if (consultationFee != null) 'consultationFee': consultationFee,
      'status': status ?? 'active',
      'profileCompleted': profileCompleted,  // ✅ RESTAURADO
    };
  }

  ProfessionalModel copyWith({
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
    String? speciality,
    String? licenseNumber,
    String? bio,
    List<String>? certifications,
    String? consultingAddress,
    Map<String, dynamic>? availability,
    double? consultationFee,
    String? status,
    bool? profileCompleted,  // ✅ RESTAURADO
  }) {
    return ProfessionalModel(
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
      speciality: speciality ?? this.speciality,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      bio: bio ?? this.bio,
      certifications: certifications ?? this.certifications,
      consultingAddress: consultingAddress ?? this.consultingAddress,
      availability: availability ?? this.availability,
      consultationFee: consultationFee ?? this.consultationFee,
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
           (consultingAddress?.isNotEmpty ?? false) &&
           (licenseNumber?.isNotEmpty ?? false) &&
           (availability != null && availability!.isNotEmpty);
  }
}