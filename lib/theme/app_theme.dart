import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF090A0D);
  static const surface = Color(0xFF111318);
  static const surfaceSoft = Color(0xFF171A20);
  static const line = Color(0xFF2A2D34);
  static const orange = Color(0xFFFF7A1A);
  static const orangeSoft = Color(0xFFFFA45B);
  static const text = Color(0xFFF4F5F7);
  static const textSoft = Color(0xFF9A9EA8);
  static const success = Color(0xFF46D18B);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme.copyWith(
        primary: AppColors.orange,
        secondary: AppColors.orangeSoft,
        surface: AppColors.surface,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.text,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          color: AppColors.text,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
        ),
        titleLarge: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: AppColors.text,
          fontSize: 16,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSoft,
          fontSize: 14,
          height: 1.35,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        hintStyle: const TextStyle(color: Color(0xFF6F737D)),
        labelStyle: const TextStyle(color: AppColors.textSoft),
        prefixIconColor: AppColors.textSoft,
        suffixIconColor: AppColors.textSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.35),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE05757)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE05757), width: 1.35),
        ),
      ),
    );
  }
}
