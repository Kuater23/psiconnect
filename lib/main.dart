import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:Psiconnect/src/screens/patient/patient_page.dart';
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

  // Configura la persistencia de sesión a nivel local
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  setPathUrlStrategy(); // Configura la estrategia de URL para evitar el "#"
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Maneja el modo oscuro
  bool _isDarkMode = false;

  // Verifica el estado de autenticación al cargar la app
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  // Función para verificar el estado de autenticación del usuario
  Future<void> _checkAuthState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        // El usuario está autenticado
        // Aquí podríamos realizar cualquier lógica adicional si es necesario
      });
    }
  }

  // Función para alternar entre modo claro y oscuro
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
        brightness: Brightness.light, // Modo claro
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, // Modo oscuro
        primaryColor: Colors.grey[900],
        hintColor: Colors.tealAccent,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomePage(), // Ruta a HomePage
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/patient': (context) => PatientPageWrapper(),
        '/professional': (context) => ProfessionalHome(
              toggleTheme: () {},
            ),
        '/professional_appointments': (context) => ProfessionalAppointments(),
        '/professional_files': (context) => ProfessionalFiles(
              patientId: '',
            ),
        '/admin': (context) => AdminPage(),
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => AuthWrapper(
              toggleTheme: _toggleTheme), // Pasamos la función de alternar tema
        );
      },
    );
  }
}

// Wrapper de autenticación
class AuthWrapper extends StatelessWidget {
  final VoidCallback toggleTheme;

  AuthWrapper({required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser == null
        ? LoginPage()
        : FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadingScreen();
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return ErrorScreen(
                    message: 'Error al obtener los datos del usuario');
              }

              final userRole = snapshot.data?.get('role') as String?;

              if (userRole == 'professional') {
                return ProfessionalHome(
                  toggleTheme:
                      toggleTheme, // Pasamos la función de alternar tema
                );
              } else if (userRole == 'patient') {
                return PatientPage(
                    email: FirebaseAuth.instance.currentUser!.email!);
              } else if (userRole == 'admin') {
                return AdminPage();
              } else {
                return ErrorScreen(message: 'Rol desconocido');
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

// Wrapper para la página del paciente, manteniendo la funcionalidad existente
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
