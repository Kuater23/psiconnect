import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Psiconnect/src/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfessionalState {
  final String uid;
  final String name;
  final String lastName;
  final String address;
  final String phone;
  final String email;
  final String dni;
  final String n_matricula;
  final String role;
  final String specialty; // Campo para especialidad
  final List<String> selectedDays;
  final String startTime;
  final String endTime;
  final int breakDuration;
  final bool isLoading;
  final bool hasData;
  final bool isEditing;

  ProfessionalState({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.address,
    required this.phone,
    required this.email,
    required this.dni,
    required this.n_matricula,
    required this.role,
    required this.specialty,
    required this.selectedDays,
    required this.startTime,
    required this.endTime,
    required this.breakDuration,
    this.isLoading = false,
    this.hasData = false,
    this.isEditing = false,
  });

  factory ProfessionalState.initial() {
    return ProfessionalState(
      uid: '',
      name: '',
      lastName: '',
      address: '',
      phone: '',
      email: '',
      dni: '',
      n_matricula: '',
      role: '',
      specialty: '',
      selectedDays: [],
      startTime: '09:00',
      endTime: '17:00',
      breakDuration: 15,
    );
  }

  ProfessionalState copyWith({
    String? uid,
    String? name,
    String? lastName,
    String? address,
    String? phone,
    String? email,
    String? dni,
    String? n_matricula,
    String? role,
    String? specialty,
    List<String>? selectedDays,
    String? startTime,
    String? endTime,
    int? breakDuration,
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
      email: email ?? this.email,
      dni: dni ?? this.dni,
      n_matricula: n_matricula ?? this.n_matricula,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
      // Se crea una copia de la lista para preservar la inmutabilidad.
      selectedDays: selectedDays ?? List<String>.from(this.selectedDays),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakDuration: breakDuration ?? this.breakDuration,
      isLoading: isLoading ?? this.isLoading,
      hasData: hasData ?? this.hasData,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class ProfessionalNotifier extends StateNotifier<ProfessionalState> {
  final FirestoreService _firestoreService;

  ProfessionalNotifier(this._firestoreService)
      : super(ProfessionalState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Primero se comprueba si ya hay un usuario autenticado.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      // Si no hay usuario, se suscribe a los cambios en el estado de autenticación.
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          _loadUserData(user.uid);
        } else {
          state = ProfessionalState.initial();
        }
      });
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      state = state.copyWith(isLoading: true);
      final data = await _firestoreService.getUserData(uid);
      
      if (data != null) {
        // Verifica que 'availability' sea un Map antes de usarlo.
        final availabilityRaw = data['availability'];
        final Map<String, dynamic> availability = availabilityRaw is Map<String, dynamic>
            ? availabilityRaw
            : {};

        state = state.copyWith(
          uid: uid,
          name: data['name'] ?? '',
          lastName: data['lastName'] ?? '',
          address: data['address'] ?? '',
          phone: data['phone'] ?? '',
          email: data['email'] ?? '',
          dni: data['dni'] ?? '',
          n_matricula: data['n_matricula'] ?? '',
          specialty: data['specialty'] ?? '',
          role: data['role'] ?? '',
          selectedDays: List<String>.from(availability['days'] ?? []),
          startTime: availability['start_time'] ?? '09:00',
          endTime: availability['end_time'] ?? '17:00',
          breakDuration: availability['break_duration'] ?? 15,
          isLoading: false,
          hasData: true,
        );
      } else {
        state = state.copyWith(isLoading: false, hasData: false);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveUserData({
    required String name,
    required String lastName,
    required String address,
    required String phone,
    required String dni,
    required String n_matricula,
    required String specialty,
    required List<String> selectedDays,
    required String startTime,
    required String endTime,
    required int breakDuration,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Se actualizan los datos en Firestore, seleccionando la colección adecuada
      // según el rol: 'doctors' para profesionales, 'patients' para pacientes.
      await _firestoreService.updateUserData(
        state.uid,
        name,
        lastName,
        address, 
        phone,
        state.email,
        dni,
        n_matricula,
        specialty,
        selectedDays,
        startTime,
        endTime,
        breakDuration,
        state.role == 'professional' ? 'doctors' : 'patients',
      );

      state = state.copyWith(
        name: name,
        lastName: lastName,
        address: address,
        phone: phone,
        dni: dni,
        n_matricula: n_matricula,
        specialty: specialty,
        selectedDays: selectedDays,
        startTime: startTime,
        endTime: endTime,
        breakDuration: breakDuration,
        isLoading: false,
        isEditing: false,
      );
    } catch (e) {
      debugPrint('Error saving user data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setEditing(bool isEditing) {
    state = state.copyWith(isEditing: isEditing);
  }

  void resetState() {
    state = ProfessionalState.initial();
  }

  Future<void> reinitialize() async {
    await _initialize();
  }
}

final professionalProvider =
    StateNotifierProvider<ProfessionalNotifier, ProfessionalState>(
  (ref) => ProfessionalNotifier(FirestoreService()),
);
