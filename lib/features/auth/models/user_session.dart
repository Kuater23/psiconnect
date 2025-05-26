class UserSession {
  final String uid;
  final String? email;
  final String role;
  final String? displayName;
  final bool isProfileComplete;

  UserSession({
    required this.uid,
    this.email,
    required this.role,
    this.displayName,
    this.isProfileComplete = false,
  });
}