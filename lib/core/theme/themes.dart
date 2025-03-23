// lib/core/theme/themes.dart

import 'package:flutter/material.dart';
import '/core/constants/app_constants.dart';

/// Light theme configuration for the app
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
    primary: AppColors.primaryColor,
    secondary: AppColors.primaryLight,
    background: AppColors.backgroundLight,
  ),
  // Optimize font rendering for web
  textTheme: _createTextTheme(),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  // Set web-specific properties
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: AppColors.primaryColor.withOpacity(0.9),
      borderRadius: BorderRadius.circular(4),
    ),
    textStyle: TextStyle(color: Colors.white),
    showDuration: Duration(seconds: 2),
  ),
  // Improve button style for web
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      minimumSize: Size(120, 45),
      padding: EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  // Improve input field style
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  // Proper slider theme
  sliderTheme: SliderThemeData(
    activeTrackColor: AppColors.primaryLight,
    inactiveTrackColor: Colors.grey[300],
    thumbColor: AppColors.primaryColor,
    overlayColor: AppColors.primaryColor.withOpacity(0.2),
  ),
  // Optimize scaffolds
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  // Add proper hover effects for web
  hoverColor: AppColors.primaryLight.withOpacity(0.1),
  splashColor: AppColors.primaryLight.withOpacity(0.3),
);

/// Dark theme configuration for the app
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryLight,
    primary: AppColors.primaryLight,
    secondary: AppColors.primaryColor,
    background: AppColors.backgroundDark,
    brightness: Brightness.dark,
  ),
  // Optimize font rendering for web
  textTheme: _createTextTheme(isDark: true),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: Color(0xFF1E2022),
  ),
  // Set web-specific properties
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: AppColors.primaryLight.withOpacity(0.9),
      borderRadius: BorderRadius.circular(4),
    ),
    textStyle: TextStyle(color: Colors.white),
    showDuration: Duration(seconds: 2),
  ),
  // Improve button style for web
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      minimumSize: Size(120, 45),
      padding: EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  // Improve input field style
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[900],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.red[300]!, width: 1),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  // Proper slider theme
  sliderTheme: SliderThemeData(
    activeTrackColor: AppColors.primaryLight,
    inactiveTrackColor: Colors.grey[700],
    thumbColor: AppColors.primaryLight,
    overlayColor: AppColors.primaryLight.withOpacity(0.2),
  ),
  // Optimize scaffolds
  scaffoldBackgroundColor: Color(0xFF121212),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  // Add proper hover effects for web
  hoverColor: AppColors.primaryLight.withOpacity(0.2),
  splashColor: AppColors.primaryLight.withOpacity(0.3),
);

/// Create optimized text theme with proper font rendering for web
TextTheme _createTextTheme({bool isDark = false}) {
  final baseTextColor = isDark ? Colors.white : Colors.black;
  
  return TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      color: baseTextColor,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.bold,
      color: baseTextColor,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: baseTextColor,
      letterSpacing: -0.25,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: baseTextColor,
      letterSpacing: -0.25,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: baseTextColor,
      letterSpacing: 0,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: baseTextColor,
      letterSpacing: 0,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: baseTextColor,
      letterSpacing: 0,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: baseTextColor,
      letterSpacing: 0.15,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: baseTextColor,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: baseTextColor.withOpacity(0.9),
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: baseTextColor.withOpacity(0.9),
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: baseTextColor.withOpacity(0.8),
      letterSpacing: 0.4,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: baseTextColor,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: baseTextColor,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: baseTextColor,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );
}