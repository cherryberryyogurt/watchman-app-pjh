import 'package:flutter/material.dart';

/// Color palette for the app based on the 와치맨 design
class ColorPalette {
  // Private constructor to prevent instantiation
  ColorPalette._();

  // Brand colors
  static const Color primary = Color(0xFFFF7E36); // 와치맨 orange
  static const Color secondary = Color(0xFFFF9559); // Lighter orange
  static const Color tertiary = Color(0xFFFFB27F); // Even lighter orange

  // Status colors
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);
  static const Color info = Color(0xFF5AC8FA);

  // Text colors - Light theme
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF6E6E6E);
  static const Color textTertiaryLight = Color(0xFF9E9E9E);
  static const Color textDisabledLight = Color(0xFFBDBDBD);
  
  // Text colors - Dark theme (based on screenshots)
  static const Color textPrimaryDark = Color(0xFFF2F2F2);
  static const Color textSecondaryDark = Color(0xFFBBBBBB);
  static const Color textTertiaryDark = Color(0xFF8A8A8A);
  static const Color textDisabledDark = Color(0xFF6E6E6E);

  // Background colors - Light theme
  static const Color backgroundLight = Color(0xFFF8F8F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF2F2F2);
  
  // Background colors - Dark theme (from screenshots)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);

  // Dividers & Borders
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF2C2C2C);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2C2C2C);

  // Overlay colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayDark = Color(0x80000000);

  // Specific UI element colors
  static const Color cardBackground = surfaceLight;
  static const Color cardBackgroundDark = surfaceDark;
  static const Color inputBackground = surfaceLight;
  static const Color inputBackgroundDark = surfaceDark;
  
  // App-specific colors (based on screenshots)
  static const Color heartIcon = Color(0xFFFF5A5A);
  static const Color iconGray = Color(0xFF8E8E93);
  static const Color tagBackground = Color(0xFF2C2C2C);
  static const Color chipBackground = Color(0xFF2A2A2A);
  static const Color notificationBadge = Color(0xFFFF3B30);
  
  // Placeholder color for images
  static const Color placeholder = Color(0xFFE0E0E0);
} 