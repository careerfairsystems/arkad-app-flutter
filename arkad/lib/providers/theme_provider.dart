import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode ? ArkadTheme.darkTheme : ArkadTheme.lightTheme;
  }
}
