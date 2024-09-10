import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';
import 'package:Psiconnect/src/screens/professional_page.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/login_page.dart';
import 'package:Psiconnect/src/screens/register_page.dart';
import 'package:Psiconnect/firebase_options.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      theme: ThemeData(
        primaryColor: Color.fromRGBO(
            1, 40, 45, 1), // Usa primaryColor en lugar de primarySwatch
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/', // Siempre apunta al HomePage al iniciar
      routes: {
        '/': (context) => HomePage(), // HomePage siempre es el inicio
        '/login': (context) =>
            LoginPage(), // LoginPage accesible desde el NavBar
        '/register': (context) => RegisterPage(),
        '/patient': (context) => PatientPageWrapper(),
        '/professional': (context) => ProfessionalPage(),
        '/admin': (context) => AdminPage(),
      },
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
