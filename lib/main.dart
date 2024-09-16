import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';
import 'package:Psiconnect/src/screens/professional/professional_home.dart';
import 'package:Psiconnect/src/screens/professional/professional_appointments.dart';
import 'package:Psiconnect/src/screens/professional/professional_files.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/login_page.dart';
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:Psiconnect/firebase_options.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Asegúrate de configurar la persistencia de sesión a nivel local
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  setPathUrlStrategy(); // Configura la estrategia de URL para evitar el "#"
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Psiconnect",
      initialRoute: '/home',
      theme: ThemeData(
        primaryColor: Color.fromRGBO(1, 40, 45, 1),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(), // Aquí se define la lógica de inicio según la autenticación
      routes: {
        '/home': (context) => HomePage(), // Ruta a HomePage
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/patient': (context) => PatientPageWrapper(),
        '/professional': (context) => ProfessionalHome(),
        '/professional_appointments': (context) => ProfessionalAppointments(),
        '/professional_files': (context) => ProfessionalFiles(),
        '/admin': (context) => AdminPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Escucha cambios en el estado de autenticación
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostrar un indicador de carga si se está restaurando la sesión
          return LoadingScreen();
        } else if (snapshot.hasError) {
          // Muestra un mensaje de error
          return ErrorScreen(message: 'Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          // Si hay un usuario autenticado, verificar el rol
          return _handleUserBasedOnRole(snapshot.data!);
        } else {
          // Si no hay usuario autenticado, redirigir al login
          return LoginPage();
        }
      },
    );
  }

  Widget _handleUserBasedOnRole(User user) {
    // Consulta Firestore u otra fuente de datos para obtener el rol del usuario
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen(); // Página de carga personalizada
        } else if (snapshot.hasError) {
          return ErrorScreen(message: 'Error al obtener el rol: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final role = snapshot.data!['role']; // Suponiendo que el rol está almacenado como 'role'
          if (role == 'professional') {
            return ProfessionalHome();
          } else if (role == 'patient') {
            return PatientPage(email: user.email!);
          } else if (role == 'admin') {
            return AdminPage();
          } else {
            return ErrorScreen(message: 'Rol desconocido');
          }
        } else {
          return LoginPage(); // Redirigir al login si no hay datos
        }
      },
    );
  }
}

// Pantalla de carga personalizada
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

// Pantalla de error personalizada
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
    if (user != null) {
      return PatientPage(email: user.email!);
    } else {
      return LoginPage(); // Redirige al login si no hay usuario autenticado
    }
  }
}
