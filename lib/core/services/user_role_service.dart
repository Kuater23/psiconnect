import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'error_logger.dart';

enum AppUserRole { patient, professional, admin, unknown }

class UserRoleService {
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Cache para evitar lecturas repetidas
  final Map<String, AppUserRole> _roleCache = {};

  /// Obtiene el rol del usuario actual autenticado
  Future<AppUserRole> getCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return AppUserRole.unknown;
    return getUserRole(uid);
  }

  /// Obtiene el rol de un usuario por su UID
  Future<AppUserRole> getUserRole(String uid) async {
    // Verificar caché primero
    if (_roleCache.containsKey(uid)) {
      return _roleCache[uid]!;
    }

    try {
      // Verificar en paralelo las tres colecciones
      final results = await Future.wait([
        _db.collection('admins').doc(uid).get(),
        _db.collection('doctors').doc(uid).get(),
        _db.collection('patients').doc(uid).get(),
      ]);

      AppUserRole role;
      if (results[0].exists) {
        role = AppUserRole.admin;
      } else if (results[1].exists) {
        role = AppUserRole.professional;
      } else if (results[2].exists) {
        role = AppUserRole.patient;
      } else {
        role = AppUserRole.unknown;
      }

      // Guardar en caché
      _roleCache[uid] = role;
      return role;
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo rol de usuario', e, st);
      return AppUserRole.unknown;
    }
  }

  /// Verifica si el usuario actual es profesional
  Future<bool> isCurrentUserProfessional() async {
    final role = await getCurrentUserRole();
    return role == AppUserRole.professional;
  }

  /// Verifica si el usuario actual es paciente
  Future<bool> isCurrentUserPatient() async {
    final role = await getCurrentUserRole();
    return role == AppUserRole.patient;
  }

  /// Verifica si el usuario actual es admin
  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == AppUserRole.admin;
  }

  /// Verifica si un usuario específico es profesional
  Future<bool> isProfessional(String uid) async {
    final role = await getUserRole(uid);
    return role == AppUserRole.professional;
  }

  /// Verifica si existe relación entre doctor y paciente
  Future<bool> hasRelation(String doctorId, String patientId) async {
    try {
      final relationId = '${doctorId}_$patientId';
      final doc = await _db.collection('doctor_patients').doc(relationId).get();
      return doc.exists && doc.data()?['status'] == 'active';
    } catch (e, st) {
      ErrorLogger.logError('Error verificando relación doctor-paciente', e, st);
      return false;
    }
  }

  /// Limpia el caché de roles (útil después de cambios de rol)
  void clearCache([String? uid]) {
    if (uid != null) {
      _roleCache.remove(uid);
    } else {
      _roleCache.clear();
    }
  }
}