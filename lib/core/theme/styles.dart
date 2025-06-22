import 'package:flutter/material.dart';
import 'color_palette.dart';
import 'dimensions.dart';

/// Common styles for reuse across the app
class Styles {
  // Private constructor to prevent instantiation
  Styles._();

  // Box shadows
  static List<BoxShadow> get shadowXs => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 1,
    ),
  ];

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static List<BoxShadow> get shadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  // Card styles
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: ColorPalette.surfaceLight,
    borderRadius: BorderRadius.circular(Dimensions.radius),
    boxShadow: shadowSm,
  );

  static BoxDecoration get cardDecorationDark => BoxDecoration(
    color: ColorPalette.surfaceDark,
    borderRadius: BorderRadius.circular(Dimensions.radius),
  );

  // Input decoration
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: ColorPalette.inputBackground,
    contentPadding: EdgeInsets.all(Dimensions.padding),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.radius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.radius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.radius),
      borderSide: BorderSide(color: ColorPalette.primary, width: 1),
    ),
  );

  // Button styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: ColorPalette.primary,
    foregroundColor: Colors.white,
    minimumSize: Size(double.infinity, Dimensions.buttonLg),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Dimensions.radiusLg),
    ),
    elevation: 0,
  );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
    foregroundColor: ColorPalette.textPrimaryLight,
    side: BorderSide(color: ColorPalette.border),
    minimumSize: Size(double.infinity, Dimensions.buttonLg),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Dimensions.radiusLg),
    ),
  );

  // Chip styles (as seen in the screenshots)
  static BoxDecoration get chipDecoration => BoxDecoration(
    color: ColorPalette.chipBackground,
    borderRadius: BorderRadius.circular(Dimensions.radiusXl),
  );

  // Tag styles (as seen in the screenshots)
  static BoxDecoration get tagDecoration => BoxDecoration(
    color: ColorPalette.tagBackground,
    borderRadius: BorderRadius.circular(Dimensions.radiusSm),
  );

  // Badge decoration
  static BoxDecoration get badgeDecoration => BoxDecoration(
    color: ColorPalette.notificationBadge,
    shape: BoxShape.circle,
  );
} 