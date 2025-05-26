import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper class to format time and date in different formats.
class TimeFormatHelper {
  // Constantes de formato para reutilización.
  static const String _dateFormat = 'dd/MM/yyyy';
  static const String _dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String _dateTimeWithSecondsFormat = 'dd/MM/yyyy HH:mm:ss';
  static const String _timeFormat24 = 'HH:mm';

  /// Formats a [TimeOfDay] into a 24-hour format string (HH:mm).
  static String formatTimeIn24Hours(TimeOfDay time) {
    // Se usa padLeft para asegurar dos dígitos.
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Parses a string in the format HH:mm into a [TimeOfDay] object.
  ///
  /// Throws a [FormatException] if the string is not in the expected format.
  static TimeOfDay parseTime(String timeString) {
    final timeParts = timeString.split(":");
    if (timeParts.length != 2) {
      throw FormatException("Invalid time format. Expected HH:mm, got: $timeString");
    }
    return TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
  }

  /// Formats a [DateTime] into a human-readable format with date and time.
  ///
  /// If [withSeconds] is true, includes seconds in the output.
  static String formatDateTime(DateTime dateTime, {bool withSeconds = false}) {
    final format = withSeconds ? DateFormat(_dateTimeWithSecondsFormat) : DateFormat(_dateTimeFormat);
    return format.format(dateTime);
  }

  /// Formats a [DateTime] into a string using the format dd/MM/yyyy.
  static String formatDate(DateTime dateTime) {
    return DateFormat(_dateFormat).format(dateTime);
  }

  /// Parses a string in the format dd/MM/yyyy into a [DateTime] object.
  ///
  /// Throws a [FormatException] if the string does not match the expected format.
  static DateTime parseDate(String dateString) {
    return DateFormat(_dateFormat).parse(dateString);
  }
}
