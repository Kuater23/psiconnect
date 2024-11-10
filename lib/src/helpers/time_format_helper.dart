// time_format_helper.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper class to format time in different formats.
class TimeFormatHelper {
  /// Formats a [TimeOfDay] into a 24-hour format string (HH:mm).
  static String formatTimeIn24Hours(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat('HH:mm'); // 24-hour format
    return format.format(dt);
  }

  /// Parses a string in the format HH:mm into a [TimeOfDay] object.
  static TimeOfDay parseTime(String timeString) {
    final timeParts = timeString.split(":");
    return TimeOfDay(
        hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
  }

  /// Formats a [DateTime] into a human-readable format with date and time.
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
