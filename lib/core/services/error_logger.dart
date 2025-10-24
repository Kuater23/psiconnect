// lib/core/services/error_logger.dart

import 'package:flutter/foundation.dart';

/// Service for centralized error logging
class ErrorLogger {
  /// Log error with contextual information
  static void logError(
    String message,
    dynamic error,
    StackTrace stackTrace, {
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('❌ ERROR: $message');
      // ignore: avoid_print
      print('Error: $error');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      if (additionalData != null) {
        // ignore: avoid_print
        print('Additional Data: $additionalData');
      }
    }

    // TODO: Integrar con Firebase Crashlytics o Sentry en producción
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
  }

  /// Log informational messages
  static void info(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('ℹ️ INFO: $message${data != null ? ' | $data' : ''}');
    }
  }

  /// Log warning messages
  static void warning(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('⚠️ WARNING: $message${data != null ? ' | $data' : ''}');
    }
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🐛 DEBUG: $message${data != null ? ' | $data' : ''}');
    }
  }

  /// Log non-critical events (info, warning)
  static void logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    LogLevel level = LogLevel.info,
  }) {
    if (kDebugMode) {
      final emoji = _getEmojiForLevel(level);
      // ignore: avoid_print
      print('$emoji ${level.name.toUpperCase()}: $eventName${parameters != null ? ' | $parameters' : ''}');
    }

    // TODO: Integrar con Firebase Analytics en producción
    // FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
  }

  static String _getEmojiForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
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