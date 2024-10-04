import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Psiconnect/src/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Estado para gestionar los datos del profesional
class ProfessionalState {
  final String? uid;
  final String? name;
  final String? lastName;
  final String? address;
  final String? phone;
  final String? documentNumber;
  final String? documentType;
  final String? licenseNumber;
  final List<String> selectedDays;
  final String? startTime;
  final String? endTime;
  final bool isLoading;
  final bool hasData;
  final bool isEditing;

  ProfessionalState({
    this.uid,
    this.name,
    this.lastName,
    this.address,
    this.phone,
    this.documentNumber,
    this.documentType,
    this.licenseNumber,
    this.selectedDays = const [],
    this.startTime,
    this.endTime,
    this.isLoading = true,
    this.hasData = false,
    this.isEditing = false,
  });

  // Copiar estado para mutabilidad
  ProfessionalState copyWith({
    String? uid,
    String? name,
    String? lastName,
    String? address,
    String? phone,
    String? documentNumber,
    String? documentType,
    String? licenseNumber,
    List<String>? selectedDays,
    String? startTime,
    String? endTime,
    bool? isLoading,
    bool? hasData,
    bool? isEditing,
  }) {
    return ProfessionalState(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      documentNumber: documentNumber ?? this.documentNumber,
      documentType: documentType ?? this.documentType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      selectedDays: selectedDays ?? this.selectedDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isLoading: isLoading ?? this.isLoading,
      hasData: hasData ?? this.hasData,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

// Notificador que maneja el estado del profesional
class ProfessionalNotifier extends StateNotifier<ProfessionalState> {
  final FirestoreService _firestoreService;

  ProfessionalNotifier(this._firestoreService)
      : super(ProfessionalState(isLoading: true)) {
    _loadUserData(); // Cargar los datos del usuario profesional al inicializar
  }

  // Método para cargar los datos del profesional desde Firestore
  Future<void> _loadUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final uid = user.uid;
      try {
        final data = await _firestoreService.getUserData(uid);
        if (data != null) {
          state = state.copyWith(
            uid: uid,
            name: data['name'] ?? '',
            lastName: data['lastName'] ?? '',
            address: data['address'] ?? '',
            phone: data['phone'] ?? '',
            documentNumber: data['documentNumber'] ?? '',
            licenseNumber: data['n_matricula']?.toString() ?? '',
            documentType: data['documentType'] ?? 'DNI',
            selectedDays: List<String>.from(data['availability']['days'] ?? []),
            startTime: data['availability']['start_time'] ?? '09:00',
            endTime: data['availability']['end_time'] ?? '17:00',
            isLoading: false,
            hasData: true,
          );
        } else {
          state = state.copyWith(isLoading: false, hasData: false);
        }
      } catch (e) {
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  // Guardar los datos del profesional
  Future<void> saveUserData({
    required String name,
    required String lastName,
    required String address,
    required String phone,
    required String documentNumber,
    required String licenseNumber,
    required List<String> selectedDays,
    required String startTime,
    required String endTime,
  }) async {
    if (state.uid == null || state.uid!.isEmpty) return;
    await _firestoreService.updateUserData(
      state.uid!,
      name,
      lastName,
      address,
      phone,
      FirebaseAuth.instance.currentUser?.email,
      state.documentType,
      documentNumber,
      int.tryParse(licenseNumber) ?? 0,
      selectedDays,
      startTime,
      endTime,
    );
    state = state.copyWith(
      name: name,
      lastName: lastName,
      address: address,
      phone: phone,
      documentNumber: documentNumber,
      licenseNumber: licenseNumber,
      selectedDays: selectedDays,
      startTime: startTime,
      endTime: endTime,
      isEditing: false,
    );
  }

  // Alternar entre edición y visualización
  void setEditing(bool isEditing) {
    state = state.copyWith(isEditing: isEditing);
  }
}

// Provider para el notificador del profesional
final professionalProvider =
    StateNotifierProvider<ProfessionalNotifier, ProfessionalState>(
        (ref) => ProfessionalNotifier(FirestoreService()));
