import 'package:Psiconnect/src/screens/home/content/contact_content.dart';
import 'package:Psiconnect/src/screens/home/content/feature_content.dart';
import 'package:Psiconnect/src/screens/home/content/home_content.dart';
import 'package:Psiconnect/src/screens/home/content/screenshots_content.dart';
import 'package:Psiconnect/src/navigation/nav_bar.dart';
import 'package:Psiconnect/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// Definición de GlobalKeys para secciones específicas de la página.
final homeKey = GlobalKey();
final featureKey = GlobalKey();
final screenshotKey = GlobalKey();
final contactKey = GlobalKey();

// Providers para manejar el estado actual de la página y si se ha hecho scroll.
final currentPageProvider = StateProvider<GlobalKey>((_) => homeKey);
final scrolledProvider = StateProvider<bool>((_) => false);

/// Widget envoltorio para la HomePage que permite refrescar el estado.
/// Se utiliza para pasar el callback [toggleTheme] a la HomePage.
class HomePageWrapper extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomePageWrapper({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _HomePageWrapperState createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  @override
  Widget build(BuildContext context) {
    return HomePage(
      onReload: () {
        setState(() {});
      },
      toggleTheme: widget.toggleTheme,
    );
  }
}

/// Pantalla principal de la aplicación que muestra contenido de inicio,
/// y utiliza un ScrollController para detectar cambios en el scroll y
/// permite navegar a las diferentes secciones mediante GlobalKeys.
class HomePage extends HookConsumerWidget {
  final VoidCallback onReload;
  final VoidCallback toggleTheme;

  const HomePage({Key? key, required this.onReload, required this.toggleTheme})
      : super(key: key);

  /// Función que actualiza el estado [scrolledProvider] según la posición del scroll.
  void onScroll(ScrollController controller, WidgetRef ref) {
    final isScrolled = ref.read(scrolledProvider);
    if (controller.position.pixels > 5 && !isScrolled) {
      ref.read(scrolledProvider.notifier).state = true;
    } else if (controller.position.pixels <= 5 && isScrolled) {
      ref.read(scrolledProvider.notifier).state = false;
    }
  }

  /// Desplaza la vista hasta el widget identificado por la [key].
  void scrollTo(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtiene un controlador de scroll utilizando Flutter Hooks.
    final scrollController = useScrollController();

    // Define y registra el listener para el scroll.
    void scrollListener() => onScroll(scrollController, ref);
    useEffect(() {
      scrollController.addListener(scrollListener);
      return () {
        scrollController.removeListener(scrollListener);
        scrollController.dispose();
      };
    }, [scrollController]);

    // Escucha cambios en currentPageProvider para desplazarse a la sección correspondiente.
    ref.listen<GlobalKey>(currentPageProvider, (_, next) {
      scrollTo(next);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // NavBar: se encarga de mostrar la navegación superior.
          NavBar(
            scrollTo: scrollTo,
            homeKey: homeKey,
            featureKey: featureKey,
            screenshotKey: screenshotKey,
            contactKey: contactKey,
            onReload: onReload,
          ),
          // Contenido principal que se puede desplazar.
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: <Widget>[
                  HomeContent(key: homeKey),
                  FeaturesContent(key: featureKey),
                  ScreenshotsContent(key: screenshotKey),
                  ContactContent(key: contactKey),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Función privada para navegar a una página según el rol.
  /// Aunque no se utiliza directamente en este widget, puede ser invocada desde la NavBar u otros widgets.
  void _navigateToRolePage(BuildContext context, String role) {
    final routes = {
      'admin': AppRoutes.admin,
      'patient': AppRoutes.patientHome,
      'professional': AppRoutes.professionalHome,
    };
    Navigator.pushNamed(context, routes[role] ?? AppRoutes.home)
        .then((_) => onReload());
  }
}
