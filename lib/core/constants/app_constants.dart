// App Configuration
import 'package:flutter/material.dart';

const String kAppName = 'Psiconnect';
const String kAppVersion = '1.0.0';

// Firebase Collections
class FirestoreCollections {
  static const String patients = 'patients';
  static const String doctors = 'doctors';
  static const String appointments = 'appointments';
  static const String admins = 'admins';
}

// Color Palette
class AppColors {
  // Primary Colors
  static const primaryColor = Color.fromRGBO(1, 40, 45, 1);
  static const primaryLight = Color.fromRGBO(11, 191, 205, 1);
  
  // Accent Colors
  static const accentBlue = Color.fromRGBO(47, 67, 88, 1);
  static const successGreen = Colors.green;
  static const errorRed = Colors.red;
  
  // Neutral Colors
  static const backgroundLight = Colors.white;
  static const backgroundDark = Colors.black;
}

// Text Styles
class AppTextStyles {
  static const headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );
}

// Appointment Constants
class AppointmentConstants {
  static const List<String> statusTypes = [
    'RESERVADO',
    'COMPLETADO',
    'CANCELADO',
  ];
  
  static const int maxAppointmentsPerDay = 10;
  static const int defaultSessionDuration = 60; // minutes
}

// Validation Constants
class ValidationConstants {
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  
  static final RegExp phoneRegex = RegExp(r'^\d{7,15}$');
  static final RegExp dniRegex = RegExp(r'^\d{7,10}$');
}

// API and External Service Constants
class ExternalServiceConstants {
  static const String googlePlayStoreUrl = 
    'https://play.google.com/store/apps/details?id=com.psiconnect.app';
  static const String appStoreUrl = 
    'https://apps.apple.com/app/psiconnect/id1234567890';
}

// Professional Specialties
class SpecialtyConstants {
  static const List<String> psychologyTypes = [
    'Psicología Clínica',
    'Psicología Educativa',
    'Psicología Organizacional',
    'Psicología Social',
    'Psicología Forense',
  ];
}

// Time and Date Constants
class TimeConstants {
  static const int workDayStartHour = 9;
  static const int workDayEndHour = 17;
  static const int defaultBreakDuration = 15; // minutes
}

// User Roles
class UserRoleConstants {
  static const String patient = 'patient';
  static const String professional = 'professional';
  static const String admin = 'admin';
}

// File and Storage Constants
class StorageConstants {
  static const List<String> allowedFileTypes = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'gif',
  ];
  
  static const int maxFileUploadSize = 10 * 1024 * 1024; // 10 MB
}