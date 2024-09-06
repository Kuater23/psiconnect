import 'package:Psiconnect/main.dart';
import 'package:Psiconnect/src/content/contact_content.dart';
import 'package:Psiconnect/src/content/feature_content.dart';
import 'package:Psiconnect/src/content/home_content.dart';
import 'package:Psiconnect/src/content/screenshots_content.dart';
import 'package:Psiconnect/src/navigation_bar/nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Psiconnect/src/screens/admin_page.dart';
import 'package:Psiconnect/src/screens/patient_page.dart';
import 'package:Psiconnect/src/screens/professional_page.dart';

final homeKey = GlobalKey();
final featureKey = GlobalKey();
final screenshotKey = GlobalKey();
final contactKey = GlobalKey();

final currentPageProvider = StateProvider<GlobalKey>((_) => homeKey);
final scrolledProvider = StateProvider<bool>((_) => false);

class HomePage extends HookConsumerWidget {
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
      return _controller.dispose;
    }, [_controller]);

    double width = MediaQuery.of(context).size.width; // Usar todo el ancho disponible

    ref
        .watch(currentPageProvider.notifier)
        .addListener(scrollTo, fireImmediately: false);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255), // Color de fondo de Psiconnect
      //appBar: AppBar(
      //title: Text('Home'),
      //actions: [
      //IconButton(
      //icon: Icon(Icons.person),
      //onPressed: () async {
      //User? user = FirebaseAuth.instance.currentUser;
      //if (user != null) {
      //DocumentSnapshot userDoc = await FirebaseFirestore.instance
      //.collection('users')
      //  .doc(user.uid)
      //    .get();
      // String role = userDoc['role'];
      //  _navigateToRolePage(context, role);
      // }
      // },
      // ),
      //],
      //),
      body: Column(
        children: [
          NavBar(
            scrollTo: scrollTo,
            homeKey: homeKey,
            featureKey: featureKey,
            screenshotKey: screenshotKey,
            contactKey: contactKey,
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
