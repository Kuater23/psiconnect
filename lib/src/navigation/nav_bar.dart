import 'package:Psiconnect/src/navigation/nav_bar_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/providers/session_provider.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final navBarColor =
        Color.fromRGBO(1, 40, 45, 1); // Color base de Psiconnect
    final textColor = Colors.white; // Letras en blanco
    final userSession = ref.watch(sessionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // Desktop layout
          return Container(
            width: MediaQuery.of(context).size.width, // Ocupar todo el ancho
            color: navBarColor, // Fondo de Psiconnect
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Row(
                children: [
                  // Logo a la izquierda
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
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

                      // Verificamos el rol del usuario para mostrar la opción "Perfil"
                      if (userSession != null)
                        NavBarButton(
                          text: 'Perfil',
                          onTap: () {
                            _navigateToRolePage(
                                context, userSession.role, onReload);
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

                      // Opciones para administradores
                      if (userSession?.role == 'admin') ...[
                        SizedBox(width: 10),
                        NavBarButton(
                          text: 'Panel de Administración',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdminPage()),
                            ).then((_) => onReload());
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
          // Mobile layout
          return Container(
            color: navBarColor, // Fondo de Psiconnect
            width: MediaQuery.of(context).size.width, // Ocupar todo el ancho
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

                // Verificamos el rol para mostrar opciones adicionales
                if (userSession != null)
                  NavBarButton(
                    text: 'Perfil',
                    onTap: () {
                      _navigateToRolePage(context, userSession.role, onReload);
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
                  NavBarButton(
                      text: 'Registrarse',
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      defaultColor: textColor),
                ],

                // Opciones para administradores
                if (userSession?.role == 'admin') ...[
                  NavBarButton(
                    text: 'Panel de Administración',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdminPage()),
                      ).then((_) => onReload());
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

  void _navigateToRolePage(
      BuildContext context, String role, VoidCallback onReload) async {
    String route;
    switch (role) {
      case 'admin':
        route = '/admin'; // Redirigir al panel de administración
        break;
      case 'patient':
        route = '/patient'; // Redirigir a la página de paciente
        break;
      case 'professional':
        route = '/professional'; // Redirigir a la página de inicio profesional
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol desconocido')),
        );
        return;
    }

    // Esperar a que los datos del usuario se actualicen en Firestore
    await Future.delayed(Duration(seconds: 2));

    // Volver a obtener los datos del usuario desde Firestore
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario no encontrado en Firestore')),
        );
        return;
      }

      final updatedRole = userDoc['role'] as String?;
      if (updatedRole != null && updatedRole == role) {
        Navigator.pushReplacementNamed(context, route).then((_) => onReload());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol desconocido')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No estás autenticado')),
      );
    }
  }
}
