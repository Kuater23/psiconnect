import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/service/auth_service.dart'; // Importación corregida
import 'login_page.dart';

// Define the scrolledProvider
final scrolledProvider = StateProvider<bool>((ref) => false);

class HomePage extends HookConsumerWidget {
  final AuthService _authService = AuthService();

  void onScroll(ScrollController controller, WidgetRef ref) {
    if (controller.offset > 100) {
      ref.read(scrolledProvider.notifier).state = true;
    } else {
      ref.read(scrolledProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = useState<User?>(FirebaseAuth.instance.currentUser);
    final scrollController = useScrollController();

    useEffect(() {
      scrollController.addListener(() => onScroll(scrollController, ref));
      return () => scrollController.removeListener(() => onScroll(scrollController, ref));
    }, [scrollController]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        controller: scrollController,
        children: [
          // Tu contenido aquí
        ],
      ),
    );
  }
}