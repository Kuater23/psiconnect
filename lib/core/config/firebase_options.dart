// lib/core/config/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Default Firebase configuration options optimized for web-only use
class FirebaseOptionsWeb {
  static FirebaseOptions get current {
    // Safety check to prevent use in non-web platforms
    if (!kIsWeb) {
      throw UnsupportedError('This application is designed for web platforms only.');
    }

    return const FirebaseOptions(
      apiKey: 'AIzaSyATXxqOAOH-ViKl8UlLgoeeSRoFRakeK_U',
      appId: '1:953533544770:web:2a3e104a25b63a807870db',
      messagingSenderId: '953533544770',
      projectId: 'psiconnect-eb98a',
      authDomain: 'psiconnect-eb98a.firebaseapp.com',
      databaseURL: 'https://psiconnect-eb98a-default-rtdb.firebaseio.com',
      storageBucket: 'psiconnect-eb98a.appspot.com',
    );
  }
}