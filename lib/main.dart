import 'package:Psiconnect/src/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/screens/login_page.dart';
import 'src/screens/register_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp(
   // options: DefaultFirebaseOptions.currentPlatform,
 // );
  setPathUrlStrategy();
  runApp(
    ProviderScope(
      child: MaterialApp(
        title: "Psiconnect",
        initialRoute: '/',
        routes: {
          '/': (context) => MyWebPage(),
          '/login': (context) => LoginPage(),
          '/register': (context) => RegisterPage(),
                
                },
      ),
    ),
  );
}