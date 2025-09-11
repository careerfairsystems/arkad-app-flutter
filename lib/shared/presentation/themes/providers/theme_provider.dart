import 'package:flutter/material.dart';
import '../arkad_theme.dart';

/// Provider for managing app theme state
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// Toggle between light and dark themes
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Set theme mode explicitly
  void setThemeMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
    }
  }

  /// Get the current theme data
  ThemeData getTheme() {
    return _isDarkMode ? ArkadTheme.darkTheme : ArkadTheme.lightTheme;
  }

  /// Get theme mode for system integration
  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}
