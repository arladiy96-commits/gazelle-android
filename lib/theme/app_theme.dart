import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF08090C);
  static const backgroundSoft = Color(0xFF0D0F13);
  static const surface = Color(0xFF111318);
  static const surfaceSoft = Color(0xFF171A20);
  static const surfaceRaised = Color(0xFF1B1E24);
  static const line = Color(0xFF292D34);

  static const orange = Color(0xFFFF7A1A);
  static const orangeSoft = Color(0xFFFFA45B);
  static const amber = Color(0xFFFFC266);

  static const text = Color(0xFFF4F5F7);
  static const textSoft = Color(0xFF9A9EA8);
  static const textDim = Color(0xFF666B75);

  static const blue = Color(0xFF5E9BFF);
  static const violet = Color(0xFF9A7BFF);
  static const red = Color(0xFFEA7468);
  static const green = Color(0xFF58C99A);
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
        error: AppColors.red,
      ),
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      dividerColor: AppColors.line,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: AppColors.text,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.4,
        ),
        headlineLarge: TextStyle(
          color: AppColors.text,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: AppColors.text,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: AppColors.text,
          fontSize: 16,
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
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: const TextStyle(color: Color(0xFF717680)),
        labelStyle: const TextStyle(color: AppColors.textSoft),
        prefixIconColor: AppColors.textSoft,
        suffixIconColor: AppColors.textSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 1.3,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.red,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}
