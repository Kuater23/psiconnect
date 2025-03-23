// lib/navigation/nav_bar.dart

import 'package:Psiconnect/features/home/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/core/widgets/responsive_widget.dart';
import '/navigation/nav_bar_button.dart';
import '/navigation/router.dart';
import '/features/auth/providers/session_provider.dart';
import 'package:go_router/go_router.dart';

/// Top navigation bar for the app
class NavBar extends ResponsiveWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  Widget buildDesktop(BuildContext context) => const DesktopNavBar();

  @override
  Widget buildMobile(BuildContext context) => const MobileNavBar();
}

/// Desktop version of the navigation bar
class DesktopNavBar extends HookConsumerWidget {
  const DesktopNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSession = ref.watch(sessionProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);
    
    return Container(
      width: MediaQuery.of(context).size.width,
      color: theme.colorScheme.primary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          child: Row(
            children: [
              // Logo
              GestureDetector(
                onTap: () => GoRouter.of(context).go(RoutePaths.home),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                ),
              ),
              const Spacer(),
              // Main navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  NavBarButton(
                    text: 'Inicio',
                    onTap: () => GoRouter.of(context).go(RoutePaths.home),
                    isActive: location == RoutePaths.home,
                    useUnderline: true,
                  ),
                  const SizedBox(width: 8),
                  NavBarButton(
                    text: 'Servicios',
                    onTap: () {
                      if (GoRouterState.of(context).matchedLocation == RoutePaths.home) {
                        // If we're already on the home page, scroll to the section
                        ref.read(homeScrollProvider).scrollToFeatures();
                      } else {
                        // Otherwise navigate to home with query parameter
                        GoRouter.of(context).go('${RoutePaths.home}?section=services');
                      }
                    },
                    isActive: false,
                    useUnderline: true,
                  ),
                  const SizedBox(width: 8),
                  NavBarButton(
                    text: 'Contacto',
                    onTap: () {
                      if (GoRouterState.of(context).matchedLocation == RoutePaths.home) {
                        // If we're already on the home page, scroll to the section
                        ref.read(homeScrollProvider).scrollToContact();
                      } else {
                        // Otherwise navigate to home with query parameter
                        GoRouter.of(context).go('${RoutePaths.home}?section=contact');
                      }
                    },
                    isActive: false,
                    useUnderline: true,
                  ),
                  const SizedBox(width: 16),
                  // User-specific options
                  if (userSession != null) ...[
                    NavBarButton(
                      text: 'Perfil',
                      onTap: () =>
                          GoRouter.of(context).go(RoutePaths.patientHome),
                      isActive: location == RoutePaths.patientHome,
                      useUnderline: true,
                    ),
                  ] else ...[
                    NavBarButton(
                      text: 'Iniciar sesión',
                      onTap: () => GoRouter.of(context).go(RoutePaths.login),
                      isActive: location == RoutePaths.login,
                      useUnderline: true,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          GoRouter.of(context).go(RoutePaths.register),
                      child: const Text('Registrarse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile version of the navigation bar (without hamburger menu)
class MobileNavBar extends HookConsumerWidget {
  const MobileNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final userSession = ref.watch(sessionProvider);

    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Logo
            GestureDetector(
              onTap: () => GoRouter.of(context).go(RoutePaths.home),
              child: Image.asset(
                'assets/images/logo.png',
                height: 40,
              ),
            ),
            const SizedBox(width: 16),
            // Navigation buttons
            NavBarButton(
              text: 'Inicio',
              onTap: () => GoRouter.of(context).go(RoutePaths.home),
              isActive: location == RoutePaths.home,
              useUnderline: true,
            ),
            const SizedBox(width: 8),
            NavBarButton(
              text: 'Servicios',
              onTap: () {
                if (GoRouterState.of(context).matchedLocation == RoutePaths.home) {
                  // If we're already on the home page, scroll to the section
                  ref.read(homeScrollProvider).scrollToFeatures();
                } else {
                  // Otherwise navigate to home with query parameter
                  GoRouter.of(context).go('${RoutePaths.home}?section=services');
                }
              },
              isActive: false,
              useUnderline: true,
            ),
            const SizedBox(width: 8),
            NavBarButton(
              text: 'Contacto',
              onTap: () {
                if (GoRouterState.of(context).matchedLocation == RoutePaths.home) {
                  // If we're already on the home page, scroll to the section
                  ref.read(homeScrollProvider).scrollToContact();
                } else {
                  // Otherwise navigate to home with query parameter
                  GoRouter.of(context).go('${RoutePaths.home}?section=contact');
                }
              },
              isActive: false,
              useUnderline: true,
            ),
            const SizedBox(width: 16),
            // User-specific options
            if (userSession != null)
              NavBarButton(
                text: 'Perfil',
                onTap: () => GoRouter.of(context).go(RoutePaths.patientHome),
                isActive: location == RoutePaths.patientHome,
                useUnderline: true,
              )
            else ...[
              NavBarButton(
                text: 'Iniciar sesión',
                onTap: () => GoRouter.of(context).go(RoutePaths.login),
                isActive: location == RoutePaths.login,
                useUnderline: true,
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go(RoutePaths.register),
                child: const Text('Registrarse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
