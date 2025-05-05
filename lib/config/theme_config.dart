import 'package:flutter/material.dart';

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

class ArkadTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: ArkadColors.arkadNavy,
      colorScheme: ColorScheme.light(
        primary: ArkadColors.arkadTurkos,
        secondary: ArkadColors.arkadNavy,
        error: ArkadColors.lightRed,
        onSecondary: ArkadColors.white,
      ),
      scaffoldBackgroundColor: ArkadColors.white,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ArkadColors.arkadTurkos,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArkadColors.lightGray.withOpacity(0.1),
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        displayMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        displaySmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        headlineLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        headlineMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        headlineSmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        titleLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        titleMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        titleSmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        bodyLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        bodyMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        bodySmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        labelLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        labelMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
        labelSmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.gray),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: ArkadColors.arkadNavy,
      colorScheme: ColorScheme.dark(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ArkadColors.arkadTurkos,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArkadColors.gray.withOpacity(0.1),
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        displayMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        displaySmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        headlineLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        headlineMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        headlineSmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        titleLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        titleMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        titleSmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        bodyLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        bodyMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        bodySmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        labelLarge: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        labelMedium: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
        labelSmall: TextStyle(fontFamily: 'MyriadProCondensed', color: ArkadColors.white),
      ),
    );
  }
}
