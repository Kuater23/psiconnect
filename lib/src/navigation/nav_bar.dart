import 'package:Psiconnect/src/navigation/nav_bar_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/providers/session_provider.dart';
import 'package:Psiconnect/src/navigation/app_routes.dart';

class NavBar extends HookConsumerWidget {
  final Function(GlobalKey) scrollTo;
  final GlobalKey homeKey;
  final GlobalKey featureKey;
  final GlobalKey screenshotKey;
  final GlobalKey contactKey;
  final VoidCallback onReload;

  const NavBar({
    Key? key,
    required this.scrollTo,
    required this.homeKey,
    required this.featureKey,
    required this.screenshotKey,
    required this.contactKey,
    required this.onReload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Definimos el color de fondo de la barra y el color del texto.
    final navBarColor = const Color.fromRGBO(1, 40, 45, 1);
    final textColor = Colors.white;
    // Obtenemos el estado de la sesión (si hay usuario autenticado, su rol, etc.).
    final userSession = ref.watch(sessionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Diseño para dispositivos anchos (desktop/tablet)
        if (constraints.maxWidth > 800) {
          return Container(
            width: MediaQuery.of(context).size.width,
            color: navBarColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Row(
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                  ),
                  const Spacer(),
                  // Botones de navegación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NavBarButton(
                        text: 'Inicio',
                        onTap: () => scrollTo(homeKey),
                        defaultColor: textColor,
                      ),
                      const SizedBox(width: 10),
                      NavBarButton(
                        text: 'Sobre nosotros',
                        onTap: () => scrollTo(featureKey),
                        defaultColor: textColor,
                      ),
                      const SizedBox(width: 10),
                      NavBarButton(
                        text: 'Servicios',
                        onTap: () => scrollTo(screenshotKey),
                        defaultColor: textColor,
                      ),
                      const SizedBox(width: 10),
                      NavBarButton(
                        text: 'Contacto',
                        onTap: () => scrollTo(contactKey),
                        defaultColor: textColor,
                      ),
                      const SizedBox(width: 10),
                      // Si el usuario está autenticado se muestra el botón "Perfil"
                      if (userSession != null)
                        NavBarButton(
                          text: 'Perfil',
                          onTap: () {
                            navigateToRolePage(context, userSession.role, onReload);
                          },
                          defaultColor: textColor,
                        )
                      else ...[
                        NavBarButton(
                          text: 'Iniciar sesión',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                          defaultColor: textColor,
                        ),
                        const SizedBox(width: 10),
                        NavBarButton(
                          text: 'Registrarse',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          defaultColor: textColor,
                        ),
                      ],
                      // Si el usuario es administrador se muestra la opción adicional.
                      if (userSession?.role == 'admin') ...[
                        const SizedBox(width: 10),
                        NavBarButton(
                          text: 'Panel de Administración',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.admin)
                                .then((_) => onReload());
                          },
                          defaultColor: textColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          // Diseño para dispositivos móviles: se muestran los botones en columna.
          return Container(
            color: navBarColor,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                NavBarButton(
                  text: 'Inicio',
                  onTap: () => scrollTo(homeKey),
                  defaultColor: textColor,
                ),
                NavBarButton(
                  text: 'Sobre nosotros',
                  onTap: () => scrollTo(featureKey),
                  defaultColor: textColor,
                ),
                NavBarButton(
                  text: 'Servicios',
                  onTap: () => scrollTo(screenshotKey),
                  defaultColor: textColor,
                ),
                NavBarButton(
                  text: 'Contacto',
                  onTap: () => scrollTo(contactKey),
                  defaultColor: textColor,
                ),
                if (userSession != null)
                  NavBarButton(
                    text: 'Perfil',
                    onTap: () {
                      navigateToRolePage(context, userSession.role, onReload);
                    },
                    defaultColor: textColor,
                  )
                else ...[
                  NavBarButton(
                    text: 'Iniciar sesión',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    defaultColor: textColor,
                  ),
                  NavBarButton(
                    text: 'Registrarse',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    defaultColor: textColor,
                  ),
                ],
                if (userSession?.role == 'admin') ...[
                  NavBarButton(
                    text: 'Panel de Administración',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.admin)
                          .then((_) => onReload());
                    },
                    defaultColor: textColor,
                  ),
                ],
              ],
            ),
          );
        }
      },
    );
  }

  /// Navega a la página correspondiente según el rol del usuario.
  void navigateToRolePage(BuildContext context, String role, VoidCallback onReload) {
    final routes = {
      'admin': AppRoutes.admin,
      'patient': AppRoutes.patientHome,
      'professional': AppRoutes.professionalHome,
    };
    Navigator.pushNamed(context, routes[role] ?? AppRoutes.home).then((_) => onReload());
  }
}
