// lib/core/services/error_logger.dart

import 'package:flutter/foundation.dart';

/// Service for centralized error logging
class ErrorLogger {
  /// Log error with contextual information
  static void logError(
    String message,
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? additionalData,
  }) {
    // In debug mode, print to console for development
    if (kDebugMode) {
      print('================= ERROR =================');
      print('Message: $message');
      print('Error: $error');
      print('Stack Trace:\n${stackTrace.toString().split('\n').take(10).join('\n')}');
      if (additionalData != null) {
        print('Additional data: $additionalData');
      }
      print('=========================================');
    }
    
    // In production, you could send to a monitoring service
    // Example: Firebase Crashlytics, Sentry, etc.
    
    // For now, we just log to console in both cases, but structure is ready for extension
    if (!kDebugMode) {
      // Store errors in localStorage for web
      _storeErrorInLocalStorage(message, error.toString());
    }
  }
  
  /// Log non-critical events (info, warning)
  static void logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    LogLevel level = LogLevel.info,
  }) {
    if (kDebugMode) {
      print('================= ${level.name.toUpperCase()} =================');
      print('Event: $eventName');
      if (parameters != null) {
        print('Parameters: $parameters');
      }
      print('=========================================');
    }
  }
  
  /// Store error in localStorage for web debugging
  static void _storeErrorInLocalStorage(String message, String errorDetails) {
    if (kIsWeb) {
      // This would use dart:js to interact with localStorage
      // In a real implementation, we'd use a js interop package
      // to store errors for debugging purposes
    }
  }
}

/// Log levels for events
enum LogLevel {
  debug,
  info,
  warning,
  error,
}