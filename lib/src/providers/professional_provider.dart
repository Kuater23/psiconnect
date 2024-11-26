import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Psiconnect/src/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfessionalState {
  final String? uid; // Unique identifier for the user
  final String? name;
  final String? lastName;
  final String? address;
  final String? phone;
  final String? dni; // Nuevo campo para DNI
  final String? n_matricula; // Nuevo campo para n_matricula
  final String? specialty; // Nuevo campo para Especialidad
  final List<String> selectedDays;
  final String? startTime;
  final String? endTime;
  final int? breakDuration; // Nuevo campo para la duración del descanso
  final bool isLoading;
  final bool hasData;
  final bool isEditing;

  ProfessionalState({
    this.uid,
    this.name,
    this.lastName,
    this.address,
    this.phone,
    this.dni, // Inicializar el nuevo campo
    this.n_matricula, // Inicializar el nuevo campo
    this.specialty, // Inicializar el nuevo campo
    this.selectedDays = const [],
    this.startTime,
    this.endTime,
    this.breakDuration, // Inicializar el nuevo campo
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
    String? dni, // Nuevo campo para DNI
    String? n_matricula, // Nuevo campo para n_matricula
    String? specialty, // Nuevo campo para Especialidad
    List<String>? selectedDays,
    String? startTime,
    String? endTime,
    int? breakDuration, // Nuevo campo para la duración del descanso
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
      dni: dni ?? this.dni, // Copiar el nuevo campo
      n_matricula: n_matricula ?? this.n_matricula, // Copiar el nuevo campo
      specialty: specialty ?? this.specialty, // Copiar el nuevo campo
      selectedDays: selectedDays ?? this.selectedDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakDuration:
          breakDuration ?? this.breakDuration, // Copiar el nuevo campo
      isLoading: isLoading ?? this.isLoading,
      hasData: hasData ?? this.hasData,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

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
          dni: data['dni'] ?? '', // Cargar el nuevo campo
          n_matricula:
              data['n_matricula']?.toString() ?? '', // Cargar el nuevo campo
          specialty: data['specialty'] ?? '', // Cargar el nuevo campo
          selectedDays: List<String>.from(availability['days'] ?? []),
          startTime: availability['start_time'] ?? '09:00',
          endTime: availability['end_time'] ?? '17:00',
          breakDuration: availability['break_duration'] ??
              15, // Cargar la duración del descanso
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
    required String dni, // Nuevo parámetro para DNI
    required String n_matricula, // Nuevo parámetro para n_matricula
    required String? specialty, // Nuevo parámetro para Especialidad
    required List<String> selectedDays,
    required String startTime,
    required String endTime,
    required int breakDuration, // Nuevo parámetro para la duración del descanso
  }) async {
    if (state.uid == null || state.uid!.isEmpty) {
      print('UID is null or empty');
      return;
    }

    try {
      print('Saving user data for UID: ${state.uid}');
      await _firestoreService.updateUserData(
        state.uid!, // Use UID to update data
        name,
        lastName,
        address,
        phone,
        FirebaseAuth.instance.currentUser?.email,
        dni, // Guardar el nuevo campo
        n_matricula, // Guardar el nuevo campo
        specialty, // Guardar el nuevo campo
        selectedDays,
        startTime,
        endTime,
        breakDuration, // Guardar la duración del descanso
      );
      print('User data saved successfully');
      state = state.copyWith(
        name: name,
        lastName: lastName,
        address: address,
        phone: phone,
        dni: dni, // Actualizar el estado con el nuevo campo
        n_matricula: n_matricula, // Actualizar el estado con el nuevo campo
        specialty: specialty, // Actualizar el estado con el nuevo campo
        selectedDays: selectedDays,
        startTime: startTime,
        endTime: endTime,
        breakDuration:
            breakDuration, // Actualizar el estado con la duración del descanso
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
  (ref) => ProfessionalNotifier(FirestoreService()),
);
