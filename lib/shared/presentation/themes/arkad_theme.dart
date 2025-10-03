import 'package:flutter/material.dart';

/// Arkad brand colors
class ArkadColors {
  static const Color arkadNavy = Color(0xFF041224);
  static const Color arkadTurkos = Color(0xFF19A1DB);
  static const Color arkadGreen = Color(0xFF74B637);
  static const Color arkadSkog = Color(0xFF426128);
  static const Color arkadOrange = Color(0xFFF66628);
  static const Color darkRed = Color(0xFF7E0000);
  static const Color lightGray = Color(0xFFD1D1D1);
  static const Color lightGreen = Color(0xFF007E3A);
  static const Color lightRed = Color(0xFFCB0000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFF333333);
  static const Color accenture = Color(0xFFA917FE);
}

/// Arkad app theme configuration
class ArkadTheme {
  static TextTheme _createTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: ArkadColors.white,
      ),
      displayMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: ArkadColors.white,
      ),
      displaySmall: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: ArkadColors.white,
      ),
      // Headline text for screen titles
      headlineLarge: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: ArkadColors.white,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: ArkadColors.white,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ArkadColors.white,
      ),
      // Title text for cards and sections
      titleLarge: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: ArkadColors.white,
      ),
      titleMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ArkadColors.white,
      ),
      titleSmall: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ArkadColors.white,
      ),
      // Body text for content
      bodyLarge: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ArkadColors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ArkadColors.white,
      ),
      bodySmall: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ArkadColors.white,
      ),
      // Label text for form labels and small UI elements
      labelLarge: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ArkadColors.arkadTurkos,
      ),
      labelMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ArkadColors.arkadTurkos,
      ),
      labelSmall: TextStyle(
        fontFamily: 'MyriadProCondensed',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: ArkadColors.arkadTurkos,
      ),
    );
  }

  /// App theme (dark theme only)
  static ThemeData get appTheme {
    return ThemeData(
      primaryColor: ArkadColors.arkadNavy,
      colorScheme: const ColorScheme.dark(
        primary: ArkadColors.arkadTurkos,
        secondary: ArkadColors.arkadGreen,
        error: ArkadColors.lightRed,
        surface: ArkadColors.gray,
        onPrimary: ArkadColors.white,
        onSecondary: ArkadColors.white,
        onError: ArkadColors.white,
      ),
      scaffoldBackgroundColor: ArkadColors.arkadNavy,
      appBarTheme: const AppBarTheme(
        backgroundColor: ArkadColors.arkadNavy,
        foregroundColor: ArkadColors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ArkadColors.arkadTurkos,
          foregroundColor: ArkadColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ArkadColors.arkadTurkos),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArkadColors.gray.withValues(alpha: .1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArkadColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArkadColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArkadColors.arkadTurkos),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArkadColors.lightRed),
        ),
      ),
      useMaterial3: true,
      fontFamily: 'MyriadProCondensed',
      textTheme: _createTextTheme(),
    );
  }
}
