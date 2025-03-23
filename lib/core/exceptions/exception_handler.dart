// lib/core/exceptions/exception_handler.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import './app_exception.dart';
import '/core/services/error_logger.dart';

/// Centralized exception handler for the app
class ExceptionHandler {
  /// Transforms various error types into standardized AppExceptions
  static AppException handleException(dynamic error, [StackTrace? stackTrace]) {
    // Log the original error
    ErrorLogger.logError(
      'Error caught in ExceptionHandler',
      error,
      stackTrace ?? StackTrace.current,
    );

    // Firebase Auth errors
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthException(error, stackTrace);
    }
    
    // Firebase Firestore errors
    if (error.toString().contains('firestore')) {
      return _handleFirestoreException(error, stackTrace);
    }

    // Network errors
    if (error.toString().contains('network') ||
        error.toString().contains('connection') ||
        error.toString().contains('socket')) {
      return NetworkException(
        'Error de conexión. Por favor, verifica tu conexión a internet.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Already an AppException - pass through
    if (error is AppException) {
      return error;
    }

    // Default case: unknown error
    return AppException(
      'Ha ocurrido un error inesperado.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handle Firebase Auth specific exceptions
  static AuthException _handleFirebaseAuthException(
    FirebaseAuthException error, 
    StackTrace? stackTrace
  ) {
    String message;
    
    switch (error.code) {
      case 'invalid-email':
        message = 'El correo electrónico no es válido.';
        break;
      case 'user-disabled':
        message = 'Esta cuenta ha sido deshabilitada.';
        break;
      case 'user-not-found':
        message = 'No existe una cuenta con este correo electrónico.';
        break;
      case 'wrong-password':
        message = 'La contraseña es incorrecta.';
        break;
      case 'email-already-in-use':
        message = 'Este correo electrónico ya está en uso.';
        break;
      case 'weak-password':
        message = 'La contraseña es demasiado débil.';
        break;
      case 'operation-not-allowed':
        message = 'Esta operación no está permitida.';
        break;
      case 'network-request-failed':
        return AuthException(
          'Error de conexión. Por favor, verifica tu conexión a internet.',
          code: error.code,
          originalError: error,
          stackTrace: stackTrace,
        );
      default:
        message = error.message ?? 'Ha ocurrido un error de autenticación.';
    }

    return AuthException(
      message,
      code: error.code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handle Firestore specific exceptions
  static DataException _handleFirestoreException(
    dynamic error, 
    StackTrace? stackTrace
  ) {
    String message;
    String? code;
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission-denied') || errorString.contains('permission denied')) {
      message = 'No tienes permisos para realizar esta operación.';
      code = 'permission-denied';
    } else if (errorString.contains('not-found') || errorString.contains('not found')) {
      message = 'El documento solicitado no existe.';
      code = 'not-found';
    } else if (errorString.contains('already-exists') || errorString.contains('already exists')) {
      message = 'El documento ya existe.';
      code = 'already-exists';
    } else {
      message = 'Error al acceder a la base de datos.';
    }

    return DataException(
      message,
      code: code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Get a user-friendly error message from any exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    
    return 'Ha ocurrido un error inesperado.';
  }
}