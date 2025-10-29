import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/repositories/base_firestore_repository.dart';
import '../models/patient_model.dart';

class PatientRepository extends BaseFirestoreRepository<PatientModel> {
  static final PatientRepository _instance = PatientRepository._internal();
  factory PatientRepository() => _instance;
  PatientRepository._internal();

  @override
  String get collectionName => 'patients';

  @override
  PatientModel fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PatientModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(PatientModel item) {
    return item.toMap();
  }

  // ==================== Métodos Específicos de Pacientes ====================

  /// Obtener pacientes por doctor
  Future<List<PatientModel>> getPatientsByDoctor(String doctorId) async {
    // Primero obtenemos los IDs de pacientes relacionados
    final doctorPatientsSnapshot = await FirebaseFirestore.instance
        .collection('doctor_patients')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'active')
        .get();

    final patientIds = doctorPatientsSnapshot.docs
        .map((doc) => doc.data()['patientId'] as String?)
        .whereType<String>()
        .toList();

    if (patientIds.isEmpty) return [];

    // Luego obtenemos los datos completos de cada paciente
    final patients = <PatientModel>[];
    for (final patientId in patientIds) {
      final patient = await read(patientId);
      if (patient != null) {
        patients.add(patient);
      }
    }

    return patients;
  }

  /// Stream de pacientes por doctor
  Stream<List<PatientModel>> streamPatientsByDoctor(String doctorId) {
    return FirebaseFirestore.instance
        .collection('doctor_patients')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      final patientIds = snapshot.docs
          .map((doc) => doc.data()['patientId'] as String?)
          .whereType<String>()
          .toList();

      if (patientIds.isEmpty) return <PatientModel>[];

      final patients = <PatientModel>[];
      for (final patientId in patientIds) {
        final patient = await read(patientId);
        if (patient != null) {
          patients.add(patient);
        }
      }

      return patients;
    });
  }

  /// Buscar pacientes por nombre
  Future<List<PatientModel>> searchByName(String searchTerm) async {
    final allPatients = await getAll();
    final lowerSearch = searchTerm.toLowerCase();

    return allPatients.where((patient) {
      final fullName = patient.fullName.toLowerCase();
      final firstName = patient.firstName?.toLowerCase() ?? '';
      final lastName = patient.lastName?.toLowerCase() ?? '';

      return fullName.contains(lowerSearch) ||
          firstName.contains(lowerSearch) ||
          lastName.contains(lowerSearch);
    }).toList();
  }

  /// Buscar por DNI
  Future<PatientModel?> findByDNI(String dni) async {
    final results = await where('dni', dni);
    return results.isNotEmpty ? results.first : null;
  }

  /// Buscar por email
  Future<PatientModel?> findByEmail(String email) async {
    final results = await where('email', email);
    return results.isNotEmpty ? results.first : null;
  }

  /// Obtener pacientes activos
  Future<List<PatientModel>> getActivePatients() async {
    return where('status', 'active');
  }

  /// Stream de pacientes activos
  Stream<List<PatientModel>> streamActivePatients() {
    return streamWhere('status', 'active');
  }
}