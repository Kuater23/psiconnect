// lib/core/providers/provider_registry.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/features/auth/providers/auth_providers.dart' as auth;
import '/features/auth/providers/session_provider.dart';
import '/features/appointments/providers/appointment_providers.dart';
import '/features/professional/providers/professional_providers.dart';
import '/features/patient/providers/patient_providers.dart';
import '/navigation/router.dart';
import '/core/theme/theme_provider.dart'; // For themeNotifierProvider
import '/features/home/screens/home_page.dart'; // For homeScrollProvider

/// Central registry of all application providers
/// 
/// This class doesn't create the providers but rather exports them
/// from their respective modules for easier discovery and documentation.
abstract class AppProviders {
  // Auth Providers
  static final authService = auth.authServiceProvider;
  static final sessionState = sessionProvider;
  static final isLoggedIn = isLoggedInProvider;
  static final userRole = userRoleProvider;
  
  // Appointment Providers
  static final appointmentService = appointmentServiceProvider;
  static final patientAppointments = patientAppointmentsProvider;
  static final professionalAppointments = professionalAppointmentsProvider;

  // Theme Providers
  static final themeMode = themeNotifierProvider;
  static final themeIcon = themeIconProvider;
  
  // Professional Providers
  static final professionalState = professionalProvider;
  
  // Navigation Providers
  static final router = routerProvider;
  static final homeScroll = homeScrollProvider;
}