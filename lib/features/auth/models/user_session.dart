class UserSession {
  final String uid;
  final String email;
  final String displayName;
  final String role; // patient, professional, admin
  final String? photoURL;
  
  UserSession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoURL,
  });
  
  @override
  String toString() {
    return 'UserSession(uid: $uid, email: $email, displayName: $displayName, role: $role)';
  }
}