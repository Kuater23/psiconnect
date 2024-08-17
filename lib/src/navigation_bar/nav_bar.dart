import 'package:Psiconnect/src/navigation_bar/nav_bar_button.dart';
import 'package:Psiconnect/src/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/navigation_bar/providers.dart';

class NavBar extends ResponsiveWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  Widget buildDesktop(BuildContext context) {
	return const DesktopNavBar();
  }

  @override
  Widget buildMobile(BuildContext context) {
	return const MobileNavBar();
  }
}

class DesktopNavBar extends HookConsumerWidget {
  const DesktopNavBar({Key? key}) : super(key: key);

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final isScrolled = ref.watch(scrolledProvider);
  final navBarColor = isScrolled ? Colors.blue : Colors.white;

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
              NavBarButton(text: 'Inicio', onTap: () {}),
              SizedBox(width: 10),
              NavBarButton(text: 'Sobre nosotros', onTap: () {}),
              SizedBox(width: 10),
              NavBarButton(text: 'Servicios', onTap: () {}),
              SizedBox(width: 10),
              NavBarButton(text: 'Contacto', onTap: () {}),
              SizedBox(width: 10),
              NavBarButton(text: 'Inicio de sesión', onTap: () {
                Navigator.pushNamed(context,'/login');
              }
            ),
              SizedBox(width: 10),
              NavBarButton(text: 'Registrarse', onTap: () {

                Navigator.pushNamed(context,'/register');
              }),
            ],
          ),
        ],
      ),
    ),
  );
}

}

class MobileNavBar extends HookConsumerWidget {
  const MobileNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
	// Implementación para la barra de navegación móvil
	return Container(
	  // Aquí puedes añadir la implementación para la versión móvil
	);
  }
}