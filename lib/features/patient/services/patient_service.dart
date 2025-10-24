import '../models/patient_model.dart';
import '../repositories/patient_repository.dart';
import '../../../core/services/error_logger.dart';

class PatientService {
  static final PatientService _instance = PatientService._internal();
  factory PatientService() => _instance;
  PatientService._internal();

  final _repository = PatientRepository();

  // ==================== CRUD Operations (delegadas al repositorio) ====================

  Future<String> createPatient(PatientModel patient) async {
    try {
      return await _repository.create(patient, id: patient.id);
    } catch (e, st) {
      ErrorLogger.logError('Error creando paciente', e, st);
      rethrow;
    }
  }

  Future<PatientModel?> getPatient(String id) async {
    try {
      return await _repository.read(id);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo paciente', e, st);
      rethrow;
    }
  }

  Future<void> updatePatient(String id, Map<String, dynamic> data) async {
    try {
      await _repository.update(id, data);
    } catch (e, st) {
      ErrorLogger.logError('Error actualizando paciente', e, st);
      rethrow;
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      await _repository.delete(id);
    } catch (e, st) {
      ErrorLogger.logError('Error eliminando paciente', e, st);
      rethrow;
    }
  }

  // ==================== Métodos de negocio ====================

  Future<List<PatientModel>> getPatientsByDoctor(String doctorId) async {
    try {
      return await _repository.getPatientsByDoctor(doctorId);
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo pacientes del doctor', e, st);
      rethrow;
    }
  }

  Stream<List<PatientModel>> streamPatientsByDoctor(String doctorId) {
    return _repository.streamPatientsByDoctor(doctorId);
  }

  Future<List<PatientModel>> searchPatients(String searchTerm) async {
    try {
      return await _repository.searchByName(searchTerm);
    } catch (e, st) {
      ErrorLogger.logError('Error buscando pacientes', e, st);
      rethrow;
    }
  }

  Future<PatientModel?> findByDNI(String dni) async {
    try {
      return await _repository.findByDNI(dni);
    } catch (e, st) {
      ErrorLogger.logError('Error buscando paciente por DNI', e, st);
      rethrow;
    }
  }

  Future<PatientModel?> findByEmail(String email) async {
    try {
      return await _repository.findByEmail(email);
    } catch (e, st) {
      ErrorLogger.logError('Error buscando paciente por email', e, st);
      rethrow;
    }
  }

  Future<List<PatientModel>> getActivePatients() async {
    try {
      return await _repository.getActivePatients();
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo pacientes activos', e, st);
      rethrow;
    }
  }

  Stream<List<PatientModel>> streamActivePatients() {
    return _repository.streamActivePatients();
  }

  /// Validar datos del paciente antes de crear/actualizar
  String? validatePatientData(PatientModel patient) {
    if (patient.email == null || patient.email!.isEmpty) {
      return 'El email es requerido';
    }

    if (patient.firstName == null || patient.firstName!.isEmpty) {
      return 'El nombre es requerido';
    }

    if (patient.lastName == null || patient.lastName!.isEmpty) {
      return 'El apellido es requerido';
    }

    return null;
  }
}
