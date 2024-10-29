import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Psiconnect/src/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Estado para gestionar los datos del profesional
class ProfessionalState {
  final String? uid; // Unique identifier for the user
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
    _initialize();
  }

  Future<void> _initialize() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print('User is authenticated with UID: ${user.uid}');
      await _loadUserData(user.uid); // Fetch user data using UID
    } else {
      print('User is not authenticated, listening for auth state changes...');
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          print('User authenticated with UID: ${user.uid}');
          _loadUserData(user.uid); // Fetch user data using UID
        } else {
          print('User is not authenticated');
          state = state.copyWith(isLoading: false);
        }
      });
    }
  }

  // Método para cargar los datos del profesional desde Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      print('Loading user data for UID: $uid');
      final data =
          await _firestoreService.getUserData(uid); // Fetch data using UID
      if (data != null) {
        print('User data loaded successfully for UID: $uid');
        final availability = data['availability'] ?? {};
        state = state.copyWith(
          uid: uid, // Store UID in state
          name: data['name'] ?? '',
          lastName: data['lastName'] ?? '',
          address: data['address'] ?? '',
          phone: data['phone'] ?? '',
          documentNumber: data['documentNumber'] ?? '',
          licenseNumber: data['n_matricula']?.toString() ?? '',
          documentType: data['documentType'] ?? 'DNI',
          selectedDays: List<String>.from(availability['days'] ?? []),
          startTime: availability['start_time'] ?? '09:00',
          endTime: availability['end_time'] ?? '17:00',
          isLoading: false,
          hasData: true,
        );
      } else {
        print('No user data found for UID: $uid');
        state = state.copyWith(isLoading: false, hasData: false);
      }
    } catch (e) {
      print('Error loading user data for UID: $uid, Error: $e');
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
    if (state.uid == null || state.uid!.isEmpty) {
      print('UID is null or empty');
      return;
    }

    // Validate and retain existing values if new values are empty
    final currentDocumentNumber = state.documentNumber?.isNotEmpty == true
        ? state.documentNumber
        : documentNumber;
    final currentLicenseNumber = state.licenseNumber?.isNotEmpty == true
        ? state.licenseNumber
        : licenseNumber;

    try {
      print('Saving user data for UID: ${state.uid}');
      await _firestoreService.updateUserData(
        state.uid!, // Use UID to update data
        name,
        lastName,
        address,
        phone,
        FirebaseAuth.instance.currentUser?.email,
        state.documentType,
        currentDocumentNumber!,
        int.tryParse(currentLicenseNumber!) ?? 0,
        selectedDays,
        startTime,
        endTime,
      );
      print('User data saved successfully');
      state = state.copyWith(
        name: name,
        lastName: lastName,
        address: address,
        phone: phone,
        documentNumber: currentDocumentNumber,
        licenseNumber: currentLicenseNumber,
        selectedDays: selectedDays,
        startTime: startTime,
        endTime: endTime,
        isEditing: false,
      );
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Método para resetear el estado del profesional
  void resetState() {
    state = ProfessionalState(isLoading: false);
  }

  // Método para re-inicializar el estado del profesional
  Future<void> reinitialize() async {
    await _initialize();
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
