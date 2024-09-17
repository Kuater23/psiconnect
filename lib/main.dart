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

  // Configura la persistencia de sesión a nivel local
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  setPathUrlStrategy(); // Configura la estrategia de URL para evitar el "#"
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// Provider para escuchar los cambios de autenticación
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provider para obtener el rol del usuario autenticado
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authProvider).asData?.value;
  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['role'] as String?;
  }
  return null;
});

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: "Psiconnect",
      theme: ThemeData(
        primaryColor: Color.fromRGBO(1, 40, 45, 1),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/home',
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
      onGenerateRoute: (settings) {
        // Manejo de rutas dinámicas si es necesario
        return MaterialPageRoute(
          builder: (context) => AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // No hay usuario autenticado, mostrar la página de inicio de sesión
          return LoginPage();
        } else {
          // Usuario autenticado, obtener el rol
          final roleAsyncValue = ref.watch(userRoleProvider);
          return roleAsyncValue.when(
            data: (role) {
              if (role == 'professional') {
                return ProfessionalHome();
              } else if (role == 'patient') {
                return PatientPage(email: user.email!);
              } else if (role == 'admin') {
                return AdminPage();
              } else {
                return ErrorScreen(message: 'Rol desconocido');
              }
            },
            loading: () => LoadingScreen(),
            error: (e, _) =>
                ErrorScreen(message: 'Error al obtener el rol: $e'),
          );
        }
      },
      loading: () => LoadingScreen(),
      error: (e, _) => ErrorScreen(message: 'Error: $e'),
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
