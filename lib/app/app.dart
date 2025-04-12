// lib/app/app.dart

import '../core/theme/themes.dart' as AppTheme;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/core/theme/theme_provider.dart';
import '/navigation/router.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

/// Main application widget for Psiconnect
class PsiconnectApp extends ConsumerWidget {
  const PsiconnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    
    // Ajuste de la barra de estado en entornos web
    _configureSystemUI();
    
    // Obtenemos la configuración del router desde el provider
    final goRouter = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Psiconnect',
      debugShowCheckedModeBanner: false,
      
      // Configuración de temas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Configuración de enrutador usando el provider
      routerConfig: goRouter,
      
      // Ajustes globales de scroll
      scrollBehavior: _WebScrollBehavior(),
      
      // Localización
      locale: const Locale('es'),
      
      // Ajustes web específicos
      onGenerateTitle: (context) => 'Psiconnect - Salud Mental',
    );
  }
  
  /// Configuración de la barra de estado
  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}

/// Comportamiento de scroll personalizado para Flutter Web
class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
  
  @override
  Widget buildScrollbar(
    BuildContext context, 
    Widget child, 
    ScrollableDetails details
  ) {
    // Mostrar siempre la barra de desplazamiento en web
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      thickness: 8,
      radius: Radius.circular(4),
      child: child,
    );
  }
}
