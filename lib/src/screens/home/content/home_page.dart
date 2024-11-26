import 'package:Psiconnect/main.dart';
import 'package:Psiconnect/src/screens/home/content/contact_content.dart';
import 'package:Psiconnect/src/screens/home/content/feature_content.dart';
import 'package:Psiconnect/src/screens/home/content/home_content.dart';
import 'package:Psiconnect/src/screens/home/content/screenshots_content.dart';
import 'package:Psiconnect/src/navigation/nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/professional/professional_home.dart';

final homeKey = GlobalKey();
final featureKey = GlobalKey();
final screenshotKey = GlobalKey();
final contactKey = GlobalKey();

final currentPageProvider = StateProvider<GlobalKey>((_) => homeKey);
final scrolledProvider = StateProvider<bool>((_) => false);

class HomePageWrapper extends StatefulWidget {
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
    );
  }
}

class HomePage extends HookConsumerWidget {
  final VoidCallback onReload;

  HomePage({required this.onReload});

  void onScroll(ScrollController controller, WidgetRef ref) {
    final isScrolled = ref.read(scrolledProvider);

    if (controller.position.pixels > 5 && !isScrolled) {
      ref.read(scrolledProvider.notifier).state = true;
    } else if (controller.position.pixels <= 5 && isScrolled) {
      ref.read(scrolledProvider.notifier).state = false;
    }
  }

  void scrollTo(GlobalKey key) => Scrollable.ensureVisible(key.currentContext!,
      duration: Duration(milliseconds: 500));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _controller = useScrollController();

    useEffect(() {
      _controller.addListener(() => onScroll(_controller, ref));
      return () {
        _controller.removeListener(() => onScroll(_controller, ref));
        _controller.dispose();
      };
    }, [_controller]);

    double width =
        MediaQuery.of(context).size.width; // Usar todo el ancho disponible

    ref
        .watch(currentPageProvider.notifier)
        .addListener(scrollTo, fireImmediately: false);

    return Scaffold(
      backgroundColor:
          Color.fromARGB(255, 255, 255, 255), // Color de fondo de Psiconnect
      body: Column(
        children: [
          NavBar(
            scrollTo: scrollTo,
            homeKey: homeKey,
            featureKey: featureKey,
            screenshotKey: screenshotKey,
            contactKey: contactKey,
            onReload: onReload, // Añadir el argumento onReload aquí
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _controller,
              child: Column(
                children: <Widget>[
                  HomeContent(key: homeKey),
                  FeaturesContent(key: featureKey),
                  ScreenshotsContent(key: screenshotKey),
                  ContactContent(key: contactKey),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRolePage(BuildContext context, String role) {
    if (role == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      ).then((_) => onReload());
    } else if (role == 'patient') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PatientPageWrapper()),
      ).then((_) => onReload());
    } else if (role == 'professional') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfessionalHome(
                  toggleTheme: () {},
                )),
      ).then((_) => onReload());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown role')),
      );
    }
  }
}
