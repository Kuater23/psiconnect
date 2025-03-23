// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing theme state
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _prefsKey = 'theme_mode';
  
  ThemeNotifier() : super(ThemeMode.light) {
    _loadSavedTheme();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newTheme;
    await _saveTheme(newTheme);
  }
  
  /// Set specific theme mode
  Future<void> setTheme(ThemeMode themeMode) async {
    state = themeMode;
    await _saveTheme(themeMode);
  }

  /// Load theme from local storage
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_prefsKey);
      
      if (savedTheme != null) {
        if (savedTheme == 'dark') {
          state = ThemeMode.dark;
        } else if (savedTheme == 'light') {
          state = ThemeMode.light;
        } else if (savedTheme == 'system') {
          state = ThemeMode.system;
        }
      } else {
        // Default to light theme if not set
        state = ThemeMode.light;
      }
    } catch (e) {
      // If there's an error, default to light theme
      state = ThemeMode.light;
    }
  }

  /// Save theme to local storage
  Future<void> _saveTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (themeMode) {
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      
      await prefs.setString(_prefsKey, themeString);
    } catch (e) {
      // Just silently fail if we can't save the theme
      debugPrint('Error saving theme preference: $e');
    }
  }
}

/// Provider for theme state
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Icon provider based on current theme
final themeIconProvider = Provider<IconData>((ref) {
  final themeMode = ref.watch(themeNotifierProvider);
  
  switch (themeMode) {
    case ThemeMode.dark:
      return Icons.light_mode;
    case ThemeMode.light:
      return Icons.dark_mode;
    case ThemeMode.system:
      return Icons.brightness_auto;
  }
});