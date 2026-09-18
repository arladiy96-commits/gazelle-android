import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Black chrome + smoked glass palette.
  static const background = Color(0xFF050607);
  static const backgroundSoft = Color(0xFF080A0D);
  static const surface = Color(0xFF0B0D10);
  static const surfaceSoft = Color(0xFF101318);
  static const surfaceRaised = Color(0xFF171A1F);
  static const line = Color(0xFF343840);
  static const chrome = Color(0xFF9BA0A8);
  static const chromeDark = Color(0xFF3B3F46);

  static const orange = Color(0xFFFF7418);
  static const orangeSoft = Color(0xFFFFA14A);
  static const amber = Color(0xFFFFC46A);

  static const text = Color(0xFFF8F9FA);
  static const textSoft = Color(0xFFB3B7BF);
  static const textDim = Color(0xFF737985);

  static const blue = Color(0xFF63A5FF);
  static const violet = Color(0xFFA88BFF);
  static const red = Color(0xFFEE766D);
  static const green = Color(0xFF59E36D);
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
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.orange,
        selectionColor: Color(0x55FF7418),
        selectionHandleColor: AppColors.orange,
      ),
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
        fillColor: const Color(0xD90B0E12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: const TextStyle(color: Color(0xFF747A84)),
        labelStyle: const TextStyle(color: AppColors.textSoft),
        prefixIconColor: AppColors.textSoft,
        suffixIconColor: AppColors.textSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF363A42)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 1.25,
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
            width: 1.25,
          ),
        ),
      ),
    );
  }
}
