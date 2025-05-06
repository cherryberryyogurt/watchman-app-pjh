import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Provider for managing theme settings
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode based on screenshots

  /// Get current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Get current theme data
  ThemeData get theme => _themeMode == ThemeMode.dark 
      ? AppTheme.darkTheme 
      : AppTheme.lightTheme;

  /// Check if dark mode is enabled
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Set theme mode
  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  /// Toggle between light and dark theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
  }
} 