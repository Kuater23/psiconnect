import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/repositories/base_firestore_repository.dart';
import '../models/professional_model.dart';

class ProfessionalRepository extends BaseFirestoreRepository<ProfessionalModel> {
  static final ProfessionalRepository _instance = ProfessionalRepository._internal();
  factory ProfessionalRepository() => _instance;
  ProfessionalRepository._internal();

  @override
  String get collectionName => 'doctors';

  @override
  ProfessionalModel fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ProfessionalModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(ProfessionalModel item) {
    return item.toMap();
  }

  // ==================== Métodos Específicos de Profesionales ====================

  /// Obtener profesionales por especialidad
  Future<List<ProfessionalModel>> getBySpeciality(String speciality) async {
    return where('speciality', speciality);
  }

  /// Stream de profesionales por especialidad
  Stream<List<ProfessionalModel>> streamBySpeciality(String speciality) {
    return streamWhere('speciality', speciality);
  }

  /// Obtener profesionales activos
  Future<List<ProfessionalModel>> getActiveProfessionals() async {
    return where('status', 'active');
  }

  /// Stream de profesionales activos
  Stream<List<ProfessionalModel>> streamActiveProfessionals() {
    return streamWhere('status', 'active');
  }

  /// Buscar profesionales por nombre
  Future<List<ProfessionalModel>> searchByName(String searchTerm) async {
    final allProfessionals = await getAll();
    final lowerSearch = searchTerm.toLowerCase();

    return allProfessionals.where((professional) {
      final fullName = professional.fullName.toLowerCase();
      final firstName = professional.firstName?.toLowerCase() ?? '';
      final lastName = professional.lastName?.toLowerCase() ?? '';

      return fullName.contains(lowerSearch) ||
          firstName.contains(lowerSearch) ||
          lastName.contains(lowerSearch);
    }).toList();
  }

  /// Buscar por número de licencia
  Future<ProfessionalModel?> findByLicenseNumber(String licenseNumber) async {
    final results = await where('licenseNumber', licenseNumber);
    return results.isNotEmpty ? results.first : null;
  }

  /// Buscar por email
  Future<ProfessionalModel?> findByEmail(String email) async {
    final results = await where('email', email);
    return results.isNotEmpty ? results.first : null;
  }

  /// Obtener profesionales con disponibilidad configurada
  Future<List<ProfessionalModel>> getProfessionalsWithAvailability() async {
    final allProfessionals = await getActiveProfessionals();
    return allProfessionals
        .where((prof) => prof.availability != null && prof.availability!.isNotEmpty)
        .toList();
  }

  /// Obtener profesionales por rango de tarifa
  Future<List<ProfessionalModel>> getByFeeRange({
    double? minFee,
    double? maxFee,
  }) async {
    final allProfessionals = await getActiveProfessionals();

    return allProfessionals.where((prof) {
      if (prof.consultationFee == null) return false;
      
      final fee = prof.consultationFee!;
      final meetsMin = minFee == null || fee >= minFee;
      final meetsMax = maxFee == null || fee <= maxFee;
      
      return meetsMin && meetsMax;
    }).toList();
  }

  /// Obtener pacientes de un profesional (usando relación doctor_patients)
  Future<List<String>> getPatientIds(String doctorId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctor_patients')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['patientId'] as String?)
          .whereType<String>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream de IDs de pacientes de un profesional
  Stream<List<String>> streamPatientIds(String doctorId) {
    return FirebaseFirestore.instance
        .collection('doctor_patients')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['patientId'] as String?)
            .whereType<String>()
            .toList());
  }

  /// Obtener profesionales ordenados por rating (si se implementa rating)
  Future<List<ProfessionalModel>> getTopRated({int limit = 10}) async {
    // Por ahora retorna activos, pero preparado para cuando se añada rating
    return complexQuery(
      whereEquals: {'status': 'active'},
      orderByField: 'createdAt',
      descending: true,
      limit: limit,
    );
  }

  /// Obtener profesionales disponibles para nuevos pacientes
  Future<List<ProfessionalModel>> getAvailableForNewPatients() async {
    final professionals = await getActiveProfessionals();
    
    // Filtra profesionales que aceptan nuevos pacientes
    // Esto puede expandirse con lógica adicional (ej: cupo máximo)
    return professionals.where((prof) {
      // Por ahora retorna todos los activos
      // Puedes añadir: prof.acceptingNewPatients == true
      return true;
    }).toList();
  }

  /// Obtener estadísticas de un profesional
  Future<Map<String, dynamic>> getProfessionalStats(String doctorId) async {
    try {
      // Contar pacientes activos
      final patientIds = await getPatientIds(doctorId);
      
      // Contar citas (scheduled y completed)
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final scheduledCount = appointmentsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'scheduled')
          .length;

      final completedCount = appointmentsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      return {
        'totalPatients': patientIds.length,
        'scheduledAppointments': scheduledCount,
        'completedAppointments': completedCount,
        'totalAppointments': appointmentsSnapshot.docs.length,
      };
    } catch (e) {
      return {
        'totalPatients': 0,
        'scheduledAppointments': 0,
        'completedAppointments': 0,
        'totalAppointments': 0,
        'error': e.toString(),
      };
    }
  }

  /// Verificar si un profesional tiene relación con un paciente
  Future<bool> hasPatient(String doctorId, String patientId) async {
    try {
      final relationId = '${doctorId}_$patientId';
      final doc = await FirebaseFirestore.instance
          .collection('doctor_patients')
          .doc(relationId)
          .get();

      return doc.exists && doc.data()?['status'] == 'active';
    } catch (e) {
      return false;
    }
  }

  /// Buscar profesionales por múltiples criterios
  Future<List<ProfessionalModel>> advancedSearch({
    String? speciality,
    double? maxFee,
    String? nameSearch,
    bool onlyWithAvailability = false,
  }) async {
    List<ProfessionalModel> results = await getActiveProfessionals();

    // Filtrar por especialidad
    if (speciality != null && speciality.isNotEmpty) {
      results = results.where((prof) => 
        prof.speciality?.toLowerCase() == speciality.toLowerCase()
      ).toList();
    }

    // Filtrar por tarifa máxima
    if (maxFee != null) {
      results = results.where((prof) => 
        prof.consultationFee != null && prof.consultationFee! <= maxFee
      ).toList();
    }

    // Filtrar por nombre
    if (nameSearch != null && nameSearch.isNotEmpty) {
      final lowerSearch = nameSearch.toLowerCase();
      results = results.where((prof) {
        final fullName = prof.fullName.toLowerCase();
        return fullName.contains(lowerSearch);
      }).toList();
    }

    // Filtrar solo con disponibilidad
    if (onlyWithAvailability) {
      results = results.where((prof) => 
        prof.availability != null && prof.availability!.isNotEmpty
      ).toList();
    }

    return results;
  }

  /// Obtener lista de especialidades únicas disponibles
  Future<List<String>> getAvailableSpecialities() async {
    final professionals = await getActiveProfessionals();
    final specialities = professionals
        .map((prof) => prof.speciality)
        .whereType<String>()
        .toSet()
        .toList();
    
    specialities.sort();
    return specialities;
  }
}