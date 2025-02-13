import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_strategy/url_strategy.dart';
import 'src/theme/themes.dart'; // Archivo donde definiste lightTheme y darkTheme
import 'src/navigation/app_routes.dart'; // Archivo con tus rutas de navegación
import 'firebase_options.dart'; // Archivo generado por Firebase CLI

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase con manejo básico de errores.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error al inicializar Firebase: $e");
  }

  // Configura la estrategia de URLs para web (quita el '#' de la URL).
  setPathUrlStrategy();

  runApp(
    // ProviderScope es necesario para usar Riverpod
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Psiconnect",
      // Se usan los temas importados desde themes.dart
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system, // Usa el modo del sistema; puedes modificarlo según tus necesidades.
      initialRoute: AppRoutes.home, // Ruta inicial definida en tu archivo de rutas.
      routes: AppRoutes.routes, // Mapa de rutas para la navegación.
      // Puedes agregar otras configuraciones (navigatorObservers, localizations, etc.) según lo requieras.
    );
  }
}
