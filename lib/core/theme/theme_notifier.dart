import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_theme.dart';

part 'theme_notifier.g.dart';

/// Theme state class to store theme information
class ThemeState {
  final ThemeMode themeMode;
  
  const ThemeState({this.themeMode = ThemeMode.dark});

  /// Creates a copy of this ThemeState with the given fields updated
  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  /// Get current theme data
  ThemeData get theme => themeMode == ThemeMode.dark 
      ? AppTheme.darkTheme 
      : AppTheme.lightTheme;

  /// Check if dark mode is enabled
  bool get isDarkMode => themeMode == ThemeMode.dark;
}

/// Theme notifier to manage theme state changes
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeState build() {
    // Return the initial state
    return const ThemeState();
  }

  /// Set theme mode
  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }

  /// Toggle between light and dark theme
  void toggleTheme() {
    final newThemeMode = state.themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    state = state.copyWith(themeMode: newThemeMode);
  }
}

// /// Provider for theme state - This will be auto-generated
// final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
//   return ThemeNotifier();
// }); 