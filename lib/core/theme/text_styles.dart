import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Text styles for the app following Apple design guidelines
class TextStyles {
  // Private constructor to prevent instantiation
  TextStyles._();

  // Base text styles
  static const TextStyle _baseTextStyle = TextStyle(
    fontFamily: 'Pretendard',
    letterSpacing: -0.3,
    height: 1.3,
    color: ColorPalette.textPrimaryLight,
  );

  // Display styles
  static final TextStyle displayLarge = _baseTextStyle.copyWith(
    fontSize: 34.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static final TextStyle displayMedium = _baseTextStyle.copyWith(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static final TextStyle displaySmall = _baseTextStyle.copyWith(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // Headline styles
  static final TextStyle headlineLarge = _baseTextStyle.copyWith(
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static final TextStyle headlineMedium = _baseTextStyle.copyWith(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static final TextStyle headlineSmall = _baseTextStyle.copyWith(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  // Title styles
  static final TextStyle titleLarge = _baseTextStyle.copyWith(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static final TextStyle titleMedium = _baseTextStyle.copyWith(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static final TextStyle titleSmall = _baseTextStyle.copyWith(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // Body styles
  static final TextStyle bodyLarge = _baseTextStyle.copyWith(
    fontSize: 17.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );

  static final TextStyle bodyMedium = _baseTextStyle.copyWith(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );

  static final TextStyle bodySmall = _baseTextStyle.copyWith(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );

  // Label styles
  static final TextStyle labelLarge = _baseTextStyle.copyWith(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );

  static final TextStyle labelMedium = _baseTextStyle.copyWith(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );

  static final TextStyle labelSmall = _baseTextStyle.copyWith(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );

  // Other specific styles (compatibility with Material naming)
  static final TextStyle headline1 = displayLarge;
  static final TextStyle headline2 = displayMedium;
  static final TextStyle headline3 = displaySmall;
  static final TextStyle headline4 = headlineLarge;
  static final TextStyle headline5 = headlineMedium;
  static final TextStyle headline6 = headlineSmall;
  static final TextStyle subtitle1 = titleLarge;
  static final TextStyle subtitle2 = titleMedium;
  static final TextStyle bodyText1 = bodyLarge;
  static final TextStyle bodyText2 = bodyMedium;
  static final TextStyle caption = labelMedium;
  static final TextStyle overline = labelSmall;
  static final TextStyle button = labelLarge.copyWith(
    fontWeight: FontWeight.w600,
  );

  static final TextStyle buttonLarge = labelLarge.copyWith(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
  );

  // Price text style (as seen in screenshots)
  static final TextStyle price = _baseTextStyle.copyWith(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  // Tag text style (as seen in screenshots)
  static final TextStyle tag = _baseTextStyle.copyWith(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );

  // The complete text theme for the app
  static final TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
} 