// lib/navigation/router.dart

import 'dart:async';

import 'package:Psiconnect/features/auth/widgets/required_profile_completion.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';

import '/core/exceptions/app_exception.dart';
import '/core/services/error_logger.dart';
import '/core/theme/theme_provider.dart';

// Admin pages
import '/features/admin/screens/admin_page.dart';

// Auth pages
import '/features/auth/screens/login_page.dart';
import '/features/auth/screens/register_page.dart';

// Home pages
import '/features/home/screens/home_page.dart';

// Patient pages
import '/features/patient/screens/patient_home.dart';
import '/features/patient/screens/patient_appointments.dart';
import '/features/patient/screens/patient_book_schedule.dart';

// Professional pages
import '/features/professional/screens/professional_home.dart';
import '/features/professional/screens/professional_appointments.dart';
import '/features/professional/screens/patient_medical_records.dart';
import '/features/professional/screens/patient_files_list.dart';

// Auth providers
import '/features/auth/providers/session_provider.dart';

/// Router paths for the application
class RoutePaths {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Patient routes
  static const String patientHome = '/patient/home';
  static const String patientAppointments = '/patient/appointments';
  static const String patientBook = '/patient/book';

  // Professional routes
  static const String professionalHome = '/professional/home';
  static const String professionalAppointments = '/professional/appointments';
  static const String patientMedicalRecords = '/professional/patient/records';
  static const String professionalPatientFiles = '/professional/patient-files';

  // Admin routes
  static const String adminHome = '/admin';
  
  // 404 Not Found route
  static const String notFound = '/404';

  static String get admin => '/admin';
  static String get requiredProfileCompletion => '/required-profile-completion';
}

extension GoRouterExtensions on GoRouter {
  // Método para reemplazar la ruta actual y limpiar la pila de navegación
  void replaceWithClearHistory(String location, {Object? extra}) {
    go(location, extra: extra);
    
    // Asegurarse de que la ruta esté completamente cargada antes de limpiar la historia
    Future.delayed(Duration(milliseconds: 100), () {
      routerDelegate.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }
  
  // Método para navegar a una ruta nombrada con limpieza de pila
  void replaceNamedWithClearHistory(String name, {Map<String, String>? pathParameters, Object? extra}) {
    goNamed(name, pathParameters: pathParameters ?? {}, extra: extra);
    
    // Asegurarse de que la ruta esté completamente cargada antes de limpiar la historia
    Future.delayed(Duration(milliseconds: 100), () {
      routerDelegate.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }
}

// 2. Extender BuildContext para facilitar el uso de estas funciones
extension RouterContextExtensions on BuildContext {
  // Reemplazar la ruta actual y limpiar la pila de navegación
  void replaceWithClearHistory(String location, {Object? extra}) {
    GoRouter.of(this).replaceWithClearHistory(location, extra: extra);
  }
  
  // Navegar a una ruta nombrada con limpieza de pila
  void replaceNamedWithClearHistory(String name, {Map<String, String>? pathParameters, Object? extra}) {
    GoRouter.of(this).replaceNamedWithClearHistory(name, pathParameters: pathParameters, extra: extra);
  }
}

/// Registrar rutas nombradas para NavigatorState.pushNamed
final Map<String, WidgetBuilder> appRoutes = {
  RoutePaths.home: (context) => const HomePage(),
  RoutePaths.login: (context) => const LoginPage(),
  RoutePaths.register: (context) => const RegisterPage(),
  RoutePaths.patientHome: (context) => PatientHome(toggleTheme: () {}),
  RoutePaths.professionalHome: (context) => ProfessionalHome(toggleTheme: () {}),
  RoutePaths.adminHome: (context) => AdminPage(),
  RoutePaths.patientAppointments: (context) => PatientAppointments(),
  RoutePaths.patientBook: (context) => PatientBookSchedule(),
  RoutePaths.professionalAppointments: (context) => ProfessionalAppointments(toggleTheme: () {}),
  RoutePaths.patientMedicalRecords: (context) => PatientMedicalRecords(
    doctorId: FirebaseAuth.instance.currentUser?.uid ?? '',
    patientId: '',
    patientName: null,
    toggleTheme: () {},
  ),
  RoutePaths.professionalPatientFiles: (context) => PatientFilesList(toggleTheme: () {}),
  RoutePaths.notFound: (context) => NotFoundPage(location: 'unknown'),
  // Otras rutas aquí
};

/// Inicializar el NavigatorState para usarlo globalmente
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider that exposes the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  // Get necessary providers for navigation
  final themeNotifier = ref.watch(themeNotifierProvider.notifier);
  
  // Función de toggle para usar con las rutas
  void toggleTheme() {
    themeNotifier.toggleTheme();
  }
  
  // Inicializar las rutas nombradas
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Actualizar el toggleTheme para cada ruta que lo necesite
    appRoutes[RoutePaths.patientHome] = (context) => PatientHome(toggleTheme: toggleTheme);
    appRoutes[RoutePaths.professionalHome] = (context) => ProfessionalHome(toggleTheme: toggleTheme);
    appRoutes[RoutePaths.professionalAppointments] = (context) => 
        ProfessionalAppointments(toggleTheme: toggleTheme);
    appRoutes[RoutePaths.patientMedicalRecords] = (context) => PatientMedicalRecords(
      doctorId: FirebaseAuth.instance.currentUser?.uid ?? '',
      patientId: '',
      patientName: null,
      toggleTheme: toggleTheme,
    );
    appRoutes[RoutePaths.professionalPatientFiles] = (context) => 
        PatientFilesList(toggleTheme: toggleTheme);
  });
  
  return GoRouter(
    navigatorKey: rootNavigatorKey,  // Usar la misma key para ambos sistemas
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: kDebugMode,
    
    // Redirección global para "/home"
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final isLoggedIn = session != null;
      final location = state.uri.path;
      
      // Verificar si el usuario está autenticado
      if (isLoggedIn) {
        // Si el usuario necesita completar su perfil, redirigir
        if (!session.isProfileComplete && 
            location != RoutePaths.requiredProfileCompletion) {
          return RoutePaths.requiredProfileCompletion;
        }
        
        // Si está en la página de login o registro y ya está autenticado,
        // redirigir a la página de inicio correspondiente
        if (location == RoutePaths.login || location == RoutePaths.register) {
          switch (session.role) {
            case 'professional':
              return RoutePaths.professionalHome;
            case 'patient':
              return RoutePaths.patientHome;
            case 'admin':
              return RoutePaths.adminHome;
            default:
              return RoutePaths.home;
          }
        }
      } else {
        // Si no está autenticado y la ruta requiere autenticación
        if (_routesRequiringAuth.contains(location)) {
          return RoutePaths.login;
        }
      }
      
      // No hay redirección necesaria
      return null;
    },
    errorBuilder: (context, state) {
      final location = state.uri.toString();
      return NotFoundPage(location: location);
    },
    routes: [
      ...AppRouter._buildRoutes(ref, themeNotifier),
      
      // Add the profile completion route
      GoRoute(
        path: RoutePaths.requiredProfileCompletion,
        builder: (context, state) {
          final session = ref.read(sessionProvider);
          if (session == null) {
            // If there's no session, we can't show the profile completion screen
            return const LoginPage(); // Or some other appropriate fallback
          }
          
          return RequiredProfileCompletion(
            userRole: session.role,
          );
        },
      ),
    ],
  );
});

/// Class for managing application routing
class AppRouter {
  // Add root navigator key
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Build all application routes
  static List<RouteBase> _buildRoutes(ProviderRef<GoRouter> ref, ThemeNotifier themeNotifier) {
    // Helper function to toggle theme
    void toggleTheme() {
      themeNotifier.toggleTheme();
    }
    
    return [
      // Public routes
      _buildPublicRoutes(),
      
      // Patient routes
      _buildPatientRoutes(toggleTheme),
      
      // Professional routes
      _buildProfessionalRoutes(ref, toggleTheme),
      
      // Admin routes
      _buildAdminRoutes(),
      
      // 404 fallback route
      GoRoute(
        path: RoutePaths.notFound,
        name: 'notFound',
        builder: (context, state) => NotFoundPage(
          location: state.uri.queryParameters['location'] ?? 'unknown',
        ),
      ),
    ];
  }
  
  /// Public routes builder
  static RouteBase _buildPublicRoutes() {
    return ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        // Home page
        GoRoute(
          path: RoutePaths.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        
        // Auth routes
        GoRoute(
          path: RoutePaths.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RoutePaths.register,
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
    );
  }
  
  /// Patient routes builder
  static RouteBase _buildPatientRoutes(VoidCallback toggleTheme) {
    return ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        // Patient home
        GoRoute(
          path: RoutePaths.patientHome,
          name: 'patientHome',
          builder: (context, state) {
            // Extraer el parámetro extra
            final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
            final bool clearHistory = extra?['clearHistory'] ?? false;
            
            // Si clearHistory es true, usar pushReplacement internamente
            if (clearHistory) {
              // Limpiar el historial usando el Navigator subyacente
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RoutePaths.patientHome, 
                  (route) => false
                );
              });
            }
            
            return PatientHome(toggleTheme: toggleTheme);
          },
        ),
        
        // Patient appointments
        GoRoute(
          path: RoutePaths.patientAppointments,
          name: 'patientAppointments',
          builder: (context, state) => PatientAppointments(),
        ),
        
        // Patient book schedule
        GoRoute(
          path: RoutePaths.patientBook,
          name: 'patientBookSchedule',
          builder: (context, state) => PatientBookSchedule(),
        ),
      ],
    );
  }
  
  /// Professional routes builder
  static RouteBase _buildProfessionalRoutes(ProviderRef<GoRouter> ref, VoidCallback toggleTheme) {
    return ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        // Professional home
        GoRoute(
          path: RoutePaths.professionalHome,
          name: 'professionalHome',
          builder: (context, state) {
            // Extraer el parámetro extra
            final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
            final bool clearHistory = extra?['clearHistory'] ?? false;
            
            // Si clearHistory es true, usar pushReplacement internamente
            if (clearHistory) {
              // Limpiar el historial usando el Navigator subyacente
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RoutePaths.professionalHome, 
                  (route) => false
                );
              });
            }
            
            return ProfessionalHome(toggleTheme: toggleTheme);
          },
        ),
        
        // Professional appointments
        GoRoute(
          path: RoutePaths.professionalAppointments,
          name: 'professionalAppointments',
          builder: (context, state) => ProfessionalAppointments(toggleTheme: toggleTheme),
        ),
        
        // Professional patient medical records
        GoRoute(
          path: RoutePaths.patientMedicalRecords,
          name: 'patientMedicalRecords',
          builder: (context, state) {
            final patientId = state.uri.queryParameters['patientId'] ?? '';
            final patientName = state.uri.queryParameters['patientName'];
            
            return PatientMedicalRecords(
              doctorId: FirebaseAuth.instance.currentUser?.uid ?? '',
              patientId: patientId,
              patientName: patientName,
              toggleTheme: toggleTheme,
            );
          },
        ),
        // Patient files list for professionals
        GoRoute(
          path: RoutePaths.professionalPatientFiles,
          name: 'professionalPatientFiles',
          builder: (context, state) => PatientFilesList(
            toggleTheme: toggleTheme,
          ),
        ),
      ],
    );
  }
  
  /// Admin routes builder
  static RouteBase _buildAdminRoutes() {
    return ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        // Admin home
        GoRoute(
          path: RoutePaths.adminHome,
          name: 'admin',
          builder: (context, state) {
            // Extraer el parámetro extra
            final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
            final bool clearHistory = extra?['clearHistory'] ?? false;
            
            // Si clearHistory es true, usar pushReplacement internamente
            if (clearHistory) {
              // Limpiar el historial usando el Navigator subyacente
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RoutePaths.adminHome, 
                  (route) => false
                );
              });
            }
            
            return AdminPage();
          },
        ),
      ],
    );
  }
}

// Define a Set of routes requiring authentication
final _routesRequiringAuth = {
  RoutePaths.patientHome,
  RoutePaths.patientAppointments,
  RoutePaths.patientBook,
  RoutePaths.professionalHome,
  RoutePaths.professionalAppointments,
  RoutePaths.patientMedicalRecords,
  RoutePaths.professionalPatientFiles,
  RoutePaths.adminHome,
  RoutePaths.requiredProfileCompletion,
};

/// 404 Not Found page
class NotFoundPage extends StatelessWidget {
  final String location;
  
  const NotFoundPage({
    Key? key,
    required this.location,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página No Encontrada'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline, 
              color: Colors.red, 
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'La ruta "$location" no existe',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Volver al Inicio'),
              onPressed: () => GoRouter.of(context).go(RoutePaths.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation helpers extension
extension RouterExtension on BuildContext {
  /// Navigate to a new route
  void go(String location) => GoRouter.of(this).go(location);
  
  /// Push a new route
  void push(String location) => GoRouter.of(this).push(location);
  
  /// Replace current route
  void replace(String location) => GoRouter.of(this).replace(location);
  
  /// Go back
  void pop() => GoRouter.of(this).pop();
  
  /// Navigate to home page
  void goHome() => go(RoutePaths.home);
  
  /// Navigate to login page
  void goLogin() => go(RoutePaths.login);
  
  /// Navigate to patient home
  void goPatientHome() => go(RoutePaths.patientHome);
  
  /// Navigate to professional home
  void goProfessionalHome() => go(RoutePaths.professionalHome);
  
  /// Navigate to admin page
  void goAdmin() => go(RoutePaths.adminHome);
  
  /// Navigate to patient book schedule
  void goPatientBookSchedule({required String appointmentId}) => go(RoutePaths.patientBook);
  
  /// Navigate to patient appointments
  void goPatientAppointments() => go(RoutePaths.patientAppointments);
  
  /// Navigate to professional appointments
  void goProfessionalAppointments() => go(RoutePaths.professionalAppointments);
  
  /// Navigate to patient medical records with query parameters
  void goPatientMedicalRecords(String patientId, {String? patientName}) {
    final queryParams = <String, String>{
      'patientId': patientId,
    };
    
    if (patientName != null) {
      queryParams['patientName'] = patientName;
    }
    
    final path = Uri(
      path: RoutePaths.patientMedicalRecords,
      queryParameters: queryParams,
    ).toString();
    
    go(path);
  }
}