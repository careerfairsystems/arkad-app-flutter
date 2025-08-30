import 'package:flutter/material.dart';
import '../shared/presentation/themes/arkad_theme.dart';

class ThemeModel extends ChangeNotifier {
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
