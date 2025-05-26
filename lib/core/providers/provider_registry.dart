// lib/core/providers/provider_registry.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/features/auth/providers/auth_providers.dart' as auth;
import '/features/auth/providers/session_provider.dart';
import '/features/appointments/providers/appointment_providers.dart';
import '/features/professional/providers/professional_providers.dart';
import '/features/patient/providers/patient_providers.dart';
import '/navigation/router.dart';
import '/core/theme/theme_provider.dart';
import '/features/home/screens/home_page.dart'; 

abstract class AppProviders {
  static final authService = auth.authServiceProvider;
  static final sessionState = sessionProvider;
  static final isLoggedIn = isLoggedInProvider;
  static final userRole = userRoleProvider;

  static final appointmentService = appointmentServiceProvider;
  static final patientAppointments = patientAppointmentsProvider;
  static final professionalAppointments = professionalAppointmentsProvider;

  static final themeMode = themeNotifierProvider;
  static final themeIcon = themeIconProvider;

  static final professionalState = professionalProvider;
  
  static final router = routerProvider;
  static final homeScroll = homeScrollProvider;
}