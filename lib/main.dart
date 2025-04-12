// lib/app/main.dart

import 'core/theme/themes.dart' as AppTheme;
import 'navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/theme/theme_provider.dart';

import 'app/app.dart';
import '/core/config/firebase_options.dart';
import '/core/services/error_logger.dart';

/// Flag to enable emulator usage during development
const bool useEmulators = false;

/// Main entry point of the application
Future<void> main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure URL strategy without hash fragments for better web URLs
  setPathUrlStrategy();

  try {
    // Initialize Firebase with web-optimized options
    await Firebase.initializeApp(
      options: FirebaseOptionsWeb.current,
    );

    // Clear any existing auth state on app start for fresh deployment
    if (kIsWeb) {
      await FirebaseAuth.instance.signOut();
    }

    // Connect to emulators if enabled (development only)
    if (useEmulators) {
      await _connectToEmulators();
    }

    // Configure Firebase specifically for web
    await _configureFirebaseForWeb();
    
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    ErrorLogger.logError('Firebase initialization failed', e, stackTrace);
    
    // In debug mode, rethrow to make errors more visible
    if (kDebugMode) {
      rethrow;
    }
  }

  // Launch app with Riverpod for state management
  runApp(
    ProviderScope(
      child: const PsiconnectApp(),
    ),
  );
}

/// Configure Firebase services specifically for web environment
Future<void> _configureFirebaseForWeb() async {
  // Auth configuration optimized for web
  await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
  // SESSION persistence keeps user logged in current tab, better than NONE for web apps
  
  // Firestore configuration optimized for web
  FirebaseFirestore.instance.settings = const Settings(
    cacheSizeBytes: 50 * 1024 * 1024, // 50MB cache, good balance for web
    persistenceEnabled: true, // Enable persistence for offline capabilities
  );
  
  debugPrint('✅ Firebase web configuration applied');
}

/// Connect to Firebase emulators for local development
Future<void> _connectToEmulators() async {
  const host = 'localhost';
  const authPort = 9099;
  const firestorePort = 8080;
  const databasePort = 9000;

  try {
    // Auth emulator
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    
    // Firestore emulator
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    
    // Enable unlimited cache for development environment
    FirebaseFirestore.instance.settings = const Settings(
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      persistenceEnabled: true,
    );
    
    debugPrint('✅ Connected to Firebase emulators on $host');
  } catch (e) {
    debugPrint('❌ Error connecting to Firebase emulators: $e');
  }
}