import '../models/professional_model.dart';
import '../repositories/professional_repository.dart';
import '../../../core/services/error_logger.dart';

class ProfessionalService {
  static final ProfessionalService _instance = ProfessionalService._internal();
  factory ProfessionalService() => _instance;
  ProfessionalService._internal();

  final _repository = ProfessionalRepository();

  // ==================== CRUD Operations (delegadas al repositorio) ====================

  Future<String> createProfessional(ProfessionalModel professional) async {
    try {
      final validation = validateProfessionalData(professional);
      if (validation != null) {
        throw Exception(validation);
      }
      
      return await _repository.create(professional, id: professional.id);
    } catch (e, st) {
      ErrorLogger.logError('Error creando profesional', e, st);
      rethrow;
    }
  }

  Future<ProfessionalModel?> getProfessional(String id) async {
    try {
      return await _repository.read(id);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo profesional', e, st);
      rethrow;
    }
  }

  Future<void> updateProfessional(String id, Map<String, dynamic> data) async {
    try {
      await _repository.update(id, data);
    } catch (e, st) {
      ErrorLogger.logError('Error actualizando profesional', e, st);
      rethrow;
    }
  }

  Future<void> deleteProfessional(String id) async {
    try {
      await _repository.delete(id);
    } catch (e, st) {
      ErrorLogger.logError('Error eliminando profesional', e, st);
      rethrow;
    }
  }

  // ==================== Métodos de Negocio ====================

  Future<List<ProfessionalModel>> getProfessionalsBySpeciality(String speciality) async {
    try {
      return await _repository.getBySpeciality(speciality);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo profesionales por especialidad', e, st);
      rethrow;
    }
  }

  Stream<List<ProfessionalModel>> streamProfessionalsBySpeciality(String speciality) {
    return _repository.streamBySpeciality(speciality);
  }

  Future<List<ProfessionalModel>> getActiveProfessionals() async {
    try {
      return await _repository.getActiveProfessionals();
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo profesionales activos', e, st);
      rethrow;
    }
  }

  Stream<List<ProfessionalModel>> streamActiveProfessionals() {
    return _repository.streamActiveProfessionals();
  }

  Future<List<ProfessionalModel>> searchProfessionals(String searchTerm) async {
    try {
      return await _repository.searchByName(searchTerm);
    } catch (e, st) {
      ErrorLogger.logError('Error buscando profesionales', e, st);
      rethrow;
    }
  }

  Future<ProfessionalModel?> findByLicenseNumber(String licenseNumber) async {
    try {
      return await _repository.findByLicenseNumber(licenseNumber);
    } catch (e, st) {
      ErrorLogger.logError('Error buscando profesional por licencia', e, st);
      rethrow;
    }
  }

  Future<ProfessionalModel?> findByEmail(String email) async {
    try {
      return await _repository.findByEmail(email);
    } catch (e, st) {
      ErrorLogger.logError('Error buscando profesional por email', e, st);
      rethrow;
    }
  }

  Future<List<ProfessionalModel>> getProfessionalsWithAvailability() async {
    try {
      return await _repository.getProfessionalsWithAvailability();
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo profesionales con disponibilidad', e, st);
      rethrow;
    }
  }

  Future<List<ProfessionalModel>> getProfessionalsByFeeRange({
    double? minFee,
    double? maxFee,
  }) async {
    try {
      return await _repository.getByFeeRange(minFee: minFee, maxFee: maxFee);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo profesionales por tarifa', e, st);
      rethrow;
    }
  }

  Future<List<String>> getPatientIds(String doctorId) async {
    try {
      return await _repository.getPatientIds(doctorId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo IDs de pacientes', e, st);
      rethrow;
    }
  }

  Stream<List<String>> streamPatientIds(String doctorId) {
    return _repository.streamPatientIds(doctorId);
  }

  Future<Map<String, dynamic>> getProfessionalStats(String doctorId) async {
    try {
      return await _repository.getProfessionalStats(doctorId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo estadísticas del profesional', e, st);
      return {
        'totalPatients': 0,
        'scheduledAppointments': 0,
        'completedAppointments': 0,
        'totalAppointments': 0,
        'error': e.toString(),
      };
    }
  }

  Future<bool> hasPatient(String doctorId, String patientId) async {
    try {
      return await _repository.hasPatient(doctorId, patientId);
    } catch (e, st) {
      ErrorLogger.logError('Error verificando relación doctor-paciente', e, st);
      return false;
    }
  }

  Future<List<ProfessionalModel>> advancedSearch({
    String? speciality,
    double? maxFee,
    String? nameSearch,
    bool onlyWithAvailability = false,
  }) async {
    try {
      return await _repository.advancedSearch(
        speciality: speciality,
        maxFee: maxFee,
        nameSearch: nameSearch,
        onlyWithAvailability: onlyWithAvailability,
      );
    } catch (e, st) {
      ErrorLogger.logError('Error en búsqueda avanzada', e, st);
      rethrow;
    }
  }

  Future<List<String>> getAvailableSpecialities() async {
    try {
      return await _repository.getAvailableSpecialities();
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo especialidades', e, st);
      rethrow;
    }
  }

  // ==================== Validaciones ====================

  String? validateProfessionalData(ProfessionalModel professional) {
    if (professional.email == null || professional.email!.isEmpty) {
      return 'El email es requerido';
    }

    if (professional.firstName == null || professional.firstName!.isEmpty) {
      return 'El nombre es requerido';
    }

    if (professional.lastName == null || professional.lastName!.isEmpty) {
      return 'El apellido es requerido';
    }

    if (professional.speciality == null || professional.speciality!.isEmpty) {
      return 'La especialidad es requerida';
    }

    if (professional.licenseNumber == null || professional.licenseNumber!.isEmpty) {
      return 'El número de licencia es requerido';
    }

    return null;
  }

  String? validateAvailability(Map<String, dynamic>? availability) {
    if (availability == null || availability.isEmpty) {
      return 'Debe configurar al menos un día de disponibilidad';
    }

    // Validar estructura de disponibilidad
    // Ejemplo: {'monday': [{'start': '09:00', 'end': '17:00'}]}
    for (final entry in availability.entries) {
      final day = entry.key;
      final slots = entry.value;

      if (slots is! List) {
        return 'Formato de disponibilidad inválido para $day';
      }

      for (final slot in slots) {
        if (slot is! Map || !slot.containsKey('start') || !slot.containsKey('end')) {
          return 'Formato de horario inválido para $day';
        }
      }
    }

    return null;
  }
}