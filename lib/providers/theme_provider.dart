import 'package:flutter/material.dart';

/// Manages the app-wide theme mode (light / dark).
/// Persists the choice across hot-restarts via a simple in-memory flag.
/// Wire this into [MultiProvider] in main.dart and consume with
/// `context.watch<ThemeProvider>().themeMode`.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // default matches the current dark UI

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}
