// lib/navigation/shared_drawer.dart

import 'package:Psiconnect/core/widgets/storage_image.dart';
import 'package:Psiconnect/features/auth/models/user_session.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/navigation/router.dart';
import '/features/auth/providers/session_provider.dart';
import '/core/theme/theme_provider.dart';
import 'package:go_router/go_router.dart';

/// Shared drawer component used across the application
class SharedDrawer extends HookConsumerWidget {
  final Function(String route)? onNavigationItemSelected;
  
  const SharedDrawer({Key? key, this.onNavigationItemSelected}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSession = ref.watch(sessionProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);
    final themeIcon = ref.watch(themeIconProvider);
    
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context, userSession),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Inicio - siempre lleva al home principal
                _buildNavigationTile(
                  context,
                  title: 'Inicio',
                  icon: Icons.home_outlined,
                  selected: location == RoutePaths.home,
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    GoRouter.of(context).go(RoutePaths.home);
                  },
                ),
                
                // Perfil - solo si está autenticado
                if (userSession != null) 
                  _buildNavigationTile(
                    context,
                    title: 'Mi Perfil',
                    icon: Icons.person_outline,
                    selected: (userSession.role == 'patient' && 
                              (location == '/patient' || location == '/patient/home')) ||
                             (userSession.role == 'professional' && 
                              (location == '/professional' || location == '/professional/home')),
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar según el rol
                      if (userSession.role == 'patient') {
                        GoRouter.of(context).go('/patient/home');
                      } else if (userSession.role == 'professional') {
                        GoRouter.of(context).go('/professional/home');
                      } else if (userSession.role == 'admin') {
                        GoRouter.of(context).go('/admin');
                      }
                    },
                  ),
                
                if (userSession == null) ...[
                  const Divider(),
                  
                  _buildNavigationTile(
                    context,
                    title: 'Iniciar Sesión',
                    icon: Icons.login,
                    selected: location == RoutePaths.login,
                    onTap: () {
                      Navigator.pop(context);
                      GoRouter.of(context).go(RoutePaths.login);
                    },
                  ),
                  
                  _buildNavigationTile(
                    context,
                    title: 'Registrarse',
                    icon: Icons.person_add_outlined,
                    selected: location == RoutePaths.register,
                    onTap: () {
                      Navigator.pop(context);
                      GoRouter.of(context).go(RoutePaths.register);
                    },
                  ),
                ] else ...[
                  const Divider(),
                  
                  // Show role-specific menu items
                  _buildRoleSpecificMenuItems(context, userSession.role, location),
                  
                  const Divider(),
                  
                  _buildNavigationTile(
                    context,
                    title: 'Cerrar Sesión',
                    icon: Icons.logout,
                    selected: false,
                    onTap: () {
                      // Show confirmation dialog before logout
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cerrar sesión'),
                          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Call the sign out method with context
                                ref.read(sessionProvider.notifier).logOut(context);
                              },
                              child: const Text('Cerrar sesión'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                
                const Divider(),
                
                // Theme toggle
                ListTile(
                  leading: Icon(themeIcon),
                  title: Text(
                    ref.watch(themeNotifierProvider) == ThemeMode.light
                        ? 'Cambiar a modo oscuro'
                        : 'Cambiar a modo claro'
                  ),
                  onTap: () {
                    ref.read(themeNotifierProvider.notifier).toggleTheme();
                    Navigator.pop(context); // Cierra el drawer
                  },
                ),
              ],
            ),
          ),
          _buildDrawerFooter(context),
        ],
      ),
    );
  }
  
  /// Build the drawer header with user information
  Widget _buildDrawerHeader(
    BuildContext context, 
    UserSession? userSession
  ) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          StorageImage(
            imagePath:'images/logo.png',
            height: 60,
          ),
          const SizedBox(height: 16),
          // User info if logged in
          if (userSession != null) ...[
            Text(
              userSession.email ?? 'No email',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getRoleTitle(userSession.role),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ] else ...[
            const Text(
              'Bienvenido a Psiconnect',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Conectando pacientes y profesionales',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build a navigation tile for the drawer
  Widget _buildNavigationTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? theme.colorScheme.secondary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? theme.colorScheme.secondary : null,
        ),
      ),
      selected: selected,
      selectedTileColor: theme.colorScheme.secondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }
  
  /// Build role-specific menu items
  Widget _buildRoleSpecificMenuItems(
    BuildContext context, 
    String role, 
    String location
  ) {
    switch (role) {
      case 'patient':
        return Column(
          children: [
            _buildNavigationTile(
              context,
              title: 'Mis Citas',
              icon: Icons.calendar_today,
              selected: location.startsWith('/patient/appointments'),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).go(RoutePaths.patientAppointments);
              },
            ),
            _buildNavigationTile(
              context,
              title: 'Solicitar Cita',
              icon: Icons.add_circle_outline,
              selected: location.startsWith('/patient/book'),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).go(RoutePaths.patientBook);
              },
            ),
            // Otras opciones para pacientes...
          ],
        );
        
      case 'professional':
        return Column(
          children: [
            _buildNavigationTile(
              context,
              title: 'Mis Citas',
              icon: Icons.calendar_today,
              selected: location.startsWith('/professional/appointments'),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).go(RoutePaths.professionalAppointments);
              },
            ),
            _buildNavigationTile(
              context,
              title: 'Archivos de Pacientes',
              icon: Icons.folder_shared,
              selected: location.startsWith('/professional/patient-files'),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).go('/professional/patient-files');
              },
            ),
            // Otras opciones para profesionales...
          ],
        );
        
      case 'admin':
        return Column(
          children: [
            _buildNavigationTile(
              context,
              title: 'Panel de Administración',
              icon: Icons.admin_panel_settings,
              selected: location.startsWith('/admin'),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).go(RoutePaths.adminHome);
              },
            ),
            // Otras opciones para administrador...
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  /// Build drawer footer with app version
  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Psiconnect v1.0.0',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          Text(
            '© 2025',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get a user-friendly role title
  String _getRoleTitle(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'professional':
        return 'Profesional';
      case 'patient':
        return 'Paciente';
      default:
        return 'Usuario';
    }
  }
}