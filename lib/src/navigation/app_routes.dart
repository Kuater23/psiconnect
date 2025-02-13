import 'package:flutter/material.dart';
import 'package:Psiconnect/src/screens/home/content/home_page.dart';
import 'package:Psiconnect/src/screens/patient/patient_home.dart';
import 'package:Psiconnect/src/screens/patient/patient_appointments.dart';
import 'package:Psiconnect/src/screens/patient/patient_files.dart';
import 'package:Psiconnect/src/screens/patient/patient_book_schedule.dart';
import 'package:Psiconnect/src/screens/professional/professional_home.dart';
import 'package:Psiconnect/src/screens/professional/professional_files.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/login_page.dart';
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:Psiconnect/src/screens/professional/my_sessions_professional.dart';
import 'package:Psiconnect/src/screens/patient/my_sessions_patient.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String patientHome = '/patient';
  static const String patientAppointments = '/patient_appointments';
  static const String patientFiles = '/patient_files';
  static const String patientBookSchedule = '/bookSchedule';
  static const String professionalHome = '/professional';
  static const String professionalFiles = '/professional_files';
  static const String admin = '/admin';
  static const String mySessionsProfessional = '/my_sessions_professional';
  static const String mySessionsPatient = '/my_sessions_patient';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => HomePageWrapper(toggleTheme: () {}),
        login: (context) => LoginPage(),
        register: (context) => RegisterPage(),
        patientHome: (context) => PatientHome(toggleTheme: () {}),
        patientAppointments: (context) => PatientAppointments(toggleTheme: () {}),
        patientFiles: (context) => PatientFiles(professionalId: '', patientId: '', toggleTheme: () {}),
        patientBookSchedule: (context) => PatientBookSchedule(toggleTheme: () {}),
        professionalHome: (context) => ProfessionalHome(toggleTheme: () {}),
        professionalFiles: (context) => ProfessionalFiles(patientId: '', toggleTheme: () {}),
        admin: (context) => AdminPage(),
        mySessionsProfessional: (context) => MySessionsProfessionalPage(toggleTheme: () {}),
        mySessionsPatient: (context) => MySessionsPatientPage(toggleTheme: () {}),
      };
}
