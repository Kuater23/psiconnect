// lib/navigation/router.dart

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
}

/// Central router configuration for the app
class AppRouter {
  // Navigation keys
  static final GlobalKey<NavigatorState> _rootNavigatorKey = 
      GlobalKey<NavigatorState>(debugLabel: 'root');
      
  static final GlobalKey<NavigatorState> _shellNavigatorKey = 
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// Helper function to get home route based on role
  static String _getHomeRouteForRole(String role) {
    switch (role) {
      case 'admin':
        return RoutePaths.adminHome;
      case 'professional':
        return RoutePaths.professionalHome;
      case 'patient':
        return RoutePaths.patientHome;
      default:
        return RoutePaths.home;
    }
  }

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
          builder: (context, state) => PatientHome(toggleTheme: toggleTheme),
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
          builder: (context, state) => ProfessionalHome(toggleTheme: toggleTheme),
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
          builder: (context, state) => AdminPage(),
        ),
      ],
    );
  }
}

/// Provider that exposes the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  // Get necessary providers for navigation
  final themeNotifier = ref.watch(themeNotifierProvider.notifier);
  
  return GoRouter(
    navigatorKey: AppRouter._rootNavigatorKey,
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: kDebugMode,
    
    // Redirección global para "/home"
    redirect: (context, state) {
      // Get the current path
      final String location = state.uri.toString();
      
      // Authentication state
      final bool isLoggedIn = ref.read(isLoggedInProvider);
      final String userRole = ref.read(userRoleProvider);
      
      // Public routes that don't require authentication
      final bool isPublicRoute = 
          location == RoutePaths.home || 
          location == RoutePaths.login || 
          location == RoutePaths.register;
          
      // Role specific routes
      final bool isPatientRoute = location.startsWith('/patient');
      final bool isProfessionalRoute = location.startsWith('/professional');
      final bool isAdminRoute = location.startsWith('/admin');
      
      // Home routes based on roles
      final String userHome = AppRouter._getHomeRouteForRole(userRole);
      
      // If user is not authenticated and trying to access protected route
      if (!isLoggedIn && !isPublicRoute) {
        return RoutePaths.login;
      }
      
      // If user is authenticated on login or register page, redirect to role-specific home
      if (isLoggedIn && (location == RoutePaths.login || location == RoutePaths.register)) {
        return userHome;
      }
      
      // If user is authenticated and on the root page, redirect to role-specific home
      if (isLoggedIn && location == RoutePaths.home) {
        return userHome;
      }
      
      // Role-based access control - only redirect if not already at user's home page
      if (isLoggedIn) {
        // Prevent redirect loops - don't redirect if user is already at their home route
        if (location == userHome) {
          return null;
        }
        
        if (isPatientRoute && userRole != 'patient' && userRole != 'admin') {
          return userHome; // Redirect non-patients away from patient routes
        }
        
        if (isProfessionalRoute && userRole != 'professional' && userRole != 'admin') {
          return userHome; // Redirect non-professionals away from professional routes
        }
        
        if (isAdminRoute && userRole != 'admin') {
          return userHome; // Redirect non-admins away from admin routes
        }
      }
      
      // Allow access to the requested page
      return null;
    },
    errorBuilder: (context, state) {
      final location = state.uri.toString();
      return NotFoundPage(location: location);
    },
    routes: AppRouter._buildRoutes(ref, themeNotifier),
  );
});

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