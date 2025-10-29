import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'error_logger.dart';

/// Servicio centralizado para navegación
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;

  /// Navegar a una ruta
  void navigateTo(String path, {Object? extra}) {
    try {
      context?.go(path, extra: extra);
    } catch (e, st) {
      ErrorLogger.logError('Error navegando a $path', e, st);
    }
  }

  /// Navegar y reemplazar la ruta actual
  void replaceTo(String path, {Object? extra}) {
    try {
      context?.replace(path, extra: extra);
    } catch (e, st) {
      ErrorLogger.logError('Error reemplazando a $path', e, st);
    }
  }

  /// Navegar con push (mantiene historial)
  void pushTo(String path, {Object? extra}) {
    try {
      context?.push(path, extra: extra);
    } catch (e, st) {
      ErrorLogger.logError('Error haciendo push a $path', e, st);
    }
  }

  /// Volver atrás
  void goBack() {
    try {
      if (context?.canPop() ?? false) {
        context?.pop();
      }
    } catch (e, st) {
      ErrorLogger.logError('Error volviendo atrás', e, st);
    }
  }

  /// Volver atrás con resultado
  void goBackWithResult<T>(T result) {
    try {
      if (context?.canPop() ?? false) {
        context?.pop(result);
      }
    } catch (e, st) {
      ErrorLogger.logError('Error volviendo atrás con resultado', e, st);
    }
  }

  /// Navegar a home del usuario según su rol
  void navigateToHome(String role) {
    switch (role) {
      case 'professional':
        navigateTo('/professional/home');
        break;
      case 'patient':
        navigateTo('/patient/home');
        break;
      case 'admin':
        navigateTo('/admin');
        break;
      default:
        navigateTo('/');
    }
  }

  /// Navegar a login
  void navigateToLogin() {
    replaceTo('/login');
  }

  /// Navegar a registro
  void navigateToRegister() {
    navigateTo('/register');
  }

  /// Mostrar diálogo
  Future<T?> showDialogCustom<T>({
    required Widget dialog,
    bool barrierDismissible = true,
  }) async {
    if (context == null) return null;
    
    try {
      return await showDialog<T>(
        context: context!,
        barrierDismissible: barrierDismissible,
        builder: (_) => dialog,
      );
    } catch (e, st) {
      ErrorLogger.logError('Error mostrando diálogo', e, st);
      return null;
    }
  }

  /// Mostrar bottom sheet
  Future<T?> showBottomSheetCustom<T>({
    required Widget sheet,
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    if (context == null) return null;
    
    try {
      return await showModalBottomSheet<T>(
        context: context!,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        builder: (_) => sheet,
      );
    } catch (e, st) {
      ErrorLogger.logError('Error mostrando bottom sheet', e, st);
      return null;
    }
  }

  /// Mostrar SnackBar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    if (context == null) return;
    
    try {
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
          backgroundColor: backgroundColor,
        ),
      );
    } catch (e, st) {
      ErrorLogger.logError('Error mostrando snackbar', e, st);
    }
  }

  /// Mostrar SnackBar de éxito
  void showSuccess(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Mostrar SnackBar de error
  void showError(String message) {
    showSnackBar(message, backgroundColor: Colors.red, duration: const Duration(seconds: 5));
  }

  /// Mostrar SnackBar de advertencia
  void showWarning(String message) {
    showSnackBar(message, backgroundColor: Colors.orange);
  }

  /// Mostrar SnackBar de info
  void showInfo(String message) {
    showSnackBar(message, backgroundColor: Colors.blue);
  }
}