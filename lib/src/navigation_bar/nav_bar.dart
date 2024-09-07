import 'package:Psiconnect/main.dart';
import 'package:Psiconnect/src/navigation_bar/nav_bar_button.dart';
import 'package:Psiconnect/src/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/providers.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/professional_page.dart';

class NavBar extends ResponsiveWidget {
  final Function(GlobalKey) scrollTo;
  final GlobalKey homeKey;
  final GlobalKey featureKey;
  final GlobalKey screenshotKey;
  final GlobalKey contactKey;

  const NavBar({
    Key? key,
    required this.scrollTo,
    required this.homeKey,
    required this.featureKey,
    required this.screenshotKey,
    required this.contactKey,
  }) : super(key: key);

  @override
  Widget buildDesktop(BuildContext context) {
    return DesktopNavBar(
      scrollTo: scrollTo,
      homeKey: homeKey,
      featureKey: featureKey,
      screenshotKey: screenshotKey,
      contactKey: contactKey,
    );
  }

  @override
  Widget buildMobile(BuildContext context) {
    return MobileNavBar(
      scrollTo: scrollTo,
      homeKey: homeKey,
      featureKey: featureKey,
      screenshotKey: screenshotKey,
      contactKey: contactKey,
    );
  }
}

class DesktopNavBar extends HookConsumerWidget {
  final Function(GlobalKey) scrollTo;
  final GlobalKey homeKey;
  final GlobalKey featureKey;
  final GlobalKey screenshotKey;
  final GlobalKey contactKey;

  const DesktopNavBar({
    Key? key,
    required this.scrollTo,
    required this.homeKey,
    required this.featureKey,
    required this.screenshotKey,
    required this.contactKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScrolled = ref.watch(scrolledProvider);
    final navBarColor = const Color(0xFF01282D); // Color base de Psiconnect
    final textColor = Colors.white; // Letras en blanco
    final userSession = ref.watch(sessionProvider);

    return Container(
      width: MediaQuery.of(context).size.width, // Ocupar todo el ancho
      color: navBarColor, // Fondo de Psiconnect
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: Row(
          children: [
            // Logo a la izquierda
            Image.asset(
              'assets/images/logo.png',
              height: 40,
            ),
            Spacer(),
            // Botones alineados a la derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavBarButton(
                  text: 'Inicio',
                  onTap: () => scrollTo(homeKey),
                  defaultColor: textColor,
                ),
                SizedBox(width: 10),
                NavBarButton(
                  text: 'Sobre nosotros',
                  onTap: () => scrollTo(featureKey),
                  defaultColor: textColor,
                ),
                SizedBox(width: 10),
                NavBarButton(
                  text: 'Servicios',
                  onTap: () => scrollTo(screenshotKey),
                  defaultColor: textColor,
                ),
                SizedBox(width: 10),
                NavBarButton(
                  text: 'Contacto',
                  onTap: () => scrollTo(contactKey),
                  defaultColor: textColor,
                ),
                SizedBox(width: 10),
                if (userSession != null)
                  NavBarButton(
                    text: 'Perfil',
                    onTap: () {
                      _navigateToRolePage(context, userSession.role);
                    },
                    defaultColor: textColor,
                  )
                else ...[
                  NavBarButton(
                      text: 'Iniciar sesión',
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      defaultColor: textColor),
                  SizedBox(width: 10),
                  NavBarButton(
                      text: 'Registrarse',
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      defaultColor: textColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRolePage(BuildContext context, String role) {
    Widget page;
    switch (role) {
      case 'admin':
        page = AdminPage();
        break;
      case 'patient':
        page = PatientPageWrapper();
        break;
      case 'professional':
        page = ProfessionalPage();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown role')),
        );
        return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

class MobileNavBar extends HookConsumerWidget {
  final Function(GlobalKey) scrollTo;
  final GlobalKey homeKey;
  final GlobalKey featureKey;
  final GlobalKey screenshotKey;
  final GlobalKey contactKey;

  const MobileNavBar({
    Key? key,
    required this.scrollTo,
    required this.homeKey,
    required this.featureKey,
    required this.screenshotKey,
    required this.contactKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSession = ref.watch(sessionProvider);

    return Container(
      color: const Color(0xFF01282D), // Fondo de Psiconnect
      width: MediaQuery.of(context).size.width, // Ocupar todo el ancho
      child: Column(
        children: [
          NavBarButton(
            text: 'Inicio',
            onTap: () => scrollTo(homeKey),
            defaultColor: Colors.white,
          ),
          NavBarButton(
            text: 'Sobre nosotros',
            onTap: () => scrollTo(featureKey),
            defaultColor: Colors.white,
          ),
          NavBarButton(
            text: 'Servicios',
            onTap: () => scrollTo(screenshotKey),
            defaultColor: Colors.white,
          ),
          NavBarButton(
            text: 'Contacto',
            onTap: () => scrollTo(contactKey),
            defaultColor: Colors.white,
          ),
          if (userSession != null)
            NavBarButton(
              text: 'Perfil',
              onTap: () {
                _navigateToRolePage(context, userSession.role);
              },
              defaultColor: Colors.white,
            )
          else ...[
            NavBarButton(
                text: 'Iniciar sesión',
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
                defaultColor: Colors.white),
            NavBarButton(
                text: 'Registrarse',
                onTap: () {
                  Navigator.pushNamed(context, '/register');
                },
                defaultColor: Colors.white),
          ],
        ],
      ),
    );
  }

  void _navigateToRolePage(BuildContext context, String role) {
    Widget page;
    switch (role) {
      case 'admin':
        page = AdminPage();
        break;
      case 'patient':
        page = PatientPageWrapper();
        break;
      case 'professional':
        page = ProfessionalPage();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown role')),
        );
        return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
