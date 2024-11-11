import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/screens/home/content/home_page.dart';
import 'package:Psiconnect/src/screens/patient/patient_home.dart';
import 'package:Psiconnect/src/screens/patient/patient_appointments.dart';
import 'package:Psiconnect/src/screens/patient/patient_files.dart';
import 'package:Psiconnect/src/screens/patient/patient_book_schedule.dart';
import 'package:Psiconnect/src/screens/professional/professional_home.dart';
import 'package:Psiconnect/src/screens/professional/professional_appointments.dart';
import 'package:Psiconnect/src/screens/professional/professional_files.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/login_page.dart';
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:Psiconnect/firebase_options.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/screens/professional/my_sessions_professional.dart'; // Importa la nueva pantalla para profesionales
import 'package:Psiconnect/src/screens/patient/my_sessions_patient.dart'; // Importa la nueva pantalla para pacientes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setPathUrlStrategy();

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Psiconnect",
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primaryColor: Color.fromRGBO(1, 40, 45, 1),
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        hintColor: Colors.tealAccent,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/patient': (context) => PatientPageWrapper(),
        '/patient_appointments': (context) => PatientAppointments(),
        '/patient_files': (context) =>
            PatientFiles(professionalId: '', patientId: ''),
        '/professional': (context) =>
            ProfessionalHome(toggleTheme: _toggleTheme),
        '/professional_appointments': (context) => ProfessionalAppointments(),
        '/professional_files': (context) => ProfessionalFiles(patientId: ''),
        '/admin': (context) => AdminPage(),
        '/bookSchedule': (context) => PatientBookSchedule(), // Define la ruta
        '/my_sessions_professional': (context) =>
            MySessionsProfessionalPage(), // Define la nueva ruta para profesionales
        '/my_sessions_patient': (context) =>
            MySessionsPatientPage(), // Define la nueva ruta para pacientes
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => AuthWrapper(toggleTheme: _toggleTheme),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  final VoidCallback toggleTheme;

  AuthWrapper({required this.toggleTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        }

        if (!snapshot.hasData) {
          return LoginPage();
        }

        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return LoadingScreen();
            }

            if (roleSnapshot.hasError || !roleSnapshot.hasData) {
              return ErrorScreen(
                  message: 'Error al obtener los datos del usuario');
            }

            final userRole = roleSnapshot.data?.get('role') as String?;

            if (userRole == 'professional') {
              return ProfessionalHome(toggleTheme: toggleTheme);
            } else if (userRole == 'patient') {
              return PatientPageWrapper();
            } else if (userRole == 'admin') {
              return AdminPage();
            } else {
              return ErrorScreen(message: 'Rol desconocido');
            }
          },
        );
      },
    );
  }
}

// Pantallas adicionales
class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;

  ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(message),
      ),
    );
  }
}

class PatientPageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? PatientPage(email: user.email!) : LoginPage();
  }
}
