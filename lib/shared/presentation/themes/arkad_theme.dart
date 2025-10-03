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
  /// Create text theme with white color for dark theme
  static TextTheme _createTextTheme() {
    const textColor = ArkadColors.white;
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'MyriadProCondensed',
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontFamily: 'MyriadProCondensed',
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'MyriadProCondensed',
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'MyriadProCondensed',
        color: textColor,
      ),
      titleLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: textColor),
      titleMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        color: textColor,
      ),
      titleSmall: TextStyle(fontFamily: 'MyriadProCondensed', color: textColor),
      bodyLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: textColor),
      bodyMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: textColor),
      bodySmall: TextStyle(fontFamily: 'MyriadProCondensed', color: textColor),
      labelLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: textColor),
      labelMedium: TextStyle(
        fontFamily: 'MyriadProCondensed',
        color: textColor,
      ),
      labelSmall: TextStyle(fontFamily: 'MyriadProCondensed', color: textColor),
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
        foregroundColor: ArkadColors.arkadTurkos,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevent darker shade on scroll
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ArkadColors.arkadTurkos,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
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
