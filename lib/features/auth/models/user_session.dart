class UserSession {
  final String uid;
  final String email;
  final String role;
  final String displayName;
  final bool isProfileComplete;

  const UserSession({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName = '',
    this.isProfileComplete = false,
  });

  UserSession copyWith({
    String? uid,
    String? email,
    String? role,
    String? displayName,
    bool? isProfileComplete,
  }) {
    return UserSession(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}