import 'package:Psiconnect/main.dart';
import 'package:Psiconnect/src/navigation_bar/nav_bar_button.dart';
import 'package:Psiconnect/src/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/providers.dart';
import 'package:Psiconnect/src/navigation_bar/session_provider.dart'; // Importa el sessionProvider
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';
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
    final navBarColor = isScrolled ? Colors.blue : Colors.white;
    final user = ref.watch(sessionProvider);

    return Container(
      color: navBarColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: Row(
          children: [
            // Logo a la izquierda
            Image.asset(
              'assets/images/logo.png', // Ruta de la imagen del logo
              height: 40, // Altura del logo
            ),
            Spacer(), // Espacio flexible entre el logo y los botones
            // Botones alineados a la derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavBarButton(text: 'Inicio', onTap: () => scrollTo(homeKey)),
                SizedBox(width: 10),
                NavBarButton(
                    text: 'Sobre nosotros', onTap: () => scrollTo(featureKey)),
                SizedBox(width: 10),
                NavBarButton(
                    text: 'Servicios', onTap: () => scrollTo(screenshotKey)),
                SizedBox(width: 10),
                NavBarButton(
                    text: 'Contacto', onTap: () => scrollTo(contactKey)),
                SizedBox(width: 10),
                if (user != null)
                  NavBarButton(
                      text: 'Perfil',
                      onTap: () async {
                        User? currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          DocumentSnapshot userDoc = await FirebaseFirestore
                              .instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .get();
                          String role = userDoc['role'];
                          _navigateToRolePage(context, role);
                        }
                      })
                else ...[
                  NavBarButton(
                      text: 'Iniciar sesión',
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      }),
                  SizedBox(width: 10),
                  NavBarButton(
                      text: 'Registrarse',
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      }),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRolePage(BuildContext context, String role) {
    if (role == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      );
    } else if (role == 'patient') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PatientPageWrapper()),
      );
    } else if (role == 'professional') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfessionalPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown role')),
      );
    }
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
    final user = ref.watch(sessionProvider);

    return Container(
      // Implementación para la barra de navegación móvil
      child: Column(
        children: [
          NavBarButton(text: 'Inicio', onTap: () => scrollTo(homeKey)),
          NavBarButton(
              text: 'Sobre nosotros', onTap: () => scrollTo(featureKey)),
          NavBarButton(text: 'Servicios', onTap: () => scrollTo(screenshotKey)),
          NavBarButton(text: 'Contacto', onTap: () => scrollTo(contactKey)),
          if (user != null)
            NavBarButton(
                text: 'Perfil',
                onTap: () async {
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get();
                    String role = userDoc['role'];
                    _navigateToRolePage(context, role);
                  }
                })
          else ...[
            NavBarButton(
                text: 'Iniciar sesión',
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                }),
            NavBarButton(
                text: 'Registrarse',
                onTap: () {
                  Navigator.pushNamed(context, '/register');
                }),
          ],
        ],
      ),
    );
  }

  void _navigateToRolePage(BuildContext context, String role) {
    if (role == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      );
    } else if (role == 'patient') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PatientPageWrapper()),
      );
    } else if (role == 'professional') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfessionalPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown role')),
      );
    }
  }
}
