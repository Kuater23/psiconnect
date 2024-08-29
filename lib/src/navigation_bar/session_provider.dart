import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, User?>((ref) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<User?> {
  SessionNotifier() : super(FirebaseAuth.instance.currentUser) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      state = user;
    });
  }

  void logIn(User user) {
    state = user;
  }

  void logOut() {
    FirebaseAuth.instance.signOut();
    state = null;
  }

}

}

