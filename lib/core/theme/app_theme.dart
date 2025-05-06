import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_palette.dart';
import 'text_styles.dart';
import 'dimensions.dart';

// Light color scheme
final lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: ColorPalette.primary,
  onPrimary: Colors.white,
  primaryContainer: ColorPalette.primary.withOpacity(0.1),
  onPrimaryContainer: ColorPalette.primary,
  secondary: ColorPalette.secondary,
  onSecondary: Colors.white,
  secondaryContainer: ColorPalette.secondary.withOpacity(0.1),
  onSecondaryContainer: ColorPalette.secondary,
  tertiary: ColorPalette.tertiary,
  onTertiary: Colors.white,
  tertiaryContainer: ColorPalette.tertiary.withOpacity(0.1),
  onTertiaryContainer: ColorPalette.tertiary,
  error: ColorPalette.error,
  onError: Colors.white,
  errorContainer: ColorPalette.error.withOpacity(0.1),
  onErrorContainer: ColorPalette.error,
  background: ColorPalette.backgroundLight,
  onBackground: ColorPalette.textPrimaryLight,
  surface: ColorPalette.surfaceLight,
  onSurface: ColorPalette.textPrimaryLight,
  outline: ColorPalette.border,
  surfaceVariant: ColorPalette.surfaceVariantLight,
  onSurfaceVariant: ColorPalette.textSecondaryLight,
);

// Dark color scheme
final darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: ColorPalette.primary,
  onPrimary: Colors.white,
  primaryContainer: ColorPalette.primary.withOpacity(0.2),
  onPrimaryContainer: ColorPalette.primary,
  secondary: ColorPalette.secondary,
  onSecondary: Colors.white,
  secondaryContainer: ColorPalette.secondary.withOpacity(0.2),
  onSecondaryContainer: ColorPalette.secondary,
  tertiary: ColorPalette.tertiary,
  onTertiary: Colors.white,
  tertiaryContainer: ColorPalette.tertiary.withOpacity(0.2),
  onTertiaryContainer: ColorPalette.tertiary,
  error: ColorPalette.error,
  onError: Colors.white,
  errorContainer: ColorPalette.error.withOpacity(0.2),
  onErrorContainer: ColorPalette.error,
  background: ColorPalette.backgroundDark,
  onBackground: ColorPalette.textPrimaryDark,
  surface: ColorPalette.surfaceDark,
  onSurface: ColorPalette.textPrimaryDark,
  outline: ColorPalette.borderDark,
  surfaceVariant: ColorPalette.surfaceVariantDark,
  onSurfaceVariant: ColorPalette.textSecondaryDark,
);

/// App theme definition
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Default text theme (applied to both light and dark themes)
  static final TextTheme textTheme = TextTheme(
    displayLarge: TextStyles.displayLarge,
    displayMedium: TextStyles.displayMedium,
    displaySmall: TextStyles.displaySmall,
    headlineLarge: TextStyles.headlineLarge,
    headlineMedium: TextStyles.headlineMedium,
    headlineSmall: TextStyles.headlineSmall,
    titleLarge: TextStyles.titleLarge,
    titleMedium: TextStyles.titleMedium,
    titleSmall: TextStyles.titleSmall,
    bodyLarge: TextStyles.bodyLarge,
    bodyMedium: TextStyles.bodyMedium,
    bodySmall: TextStyles.bodySmall,
    labelLarge: TextStyles.labelLarge,
    labelMedium: TextStyles.labelMedium,
    labelSmall: TextStyles.labelSmall,
  );

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    textTheme: textTheme,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: ColorPalette.backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorPalette.surfaceLight,
      elevation: 0,
      iconTheme: IconThemeData(color: ColorPalette.textPrimaryLight),
      titleTextStyle: TextStyle(
        color: ColorPalette.textPrimaryLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Pretendard',
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: ColorPalette.primary,
      unselectedLabelColor: ColorPalette.textSecondaryLight,
      indicatorColor: ColorPalette.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyles.subtitle1,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ColorPalette.backgroundLight,
      selectedItemColor: ColorPalette.primary,
      unselectedItemColor: ColorPalette.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyles.caption,
      unselectedLabelStyle: TextStyles.caption,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radius),
      ),
      color: ColorPalette.surfaceLight,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorPalette.surfaceLight,
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
      contentPadding: EdgeInsets.all(Dimensions.padding),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        textStyle: TextStyles.button,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorPalette.primary,
        textStyle: TextStyles.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorPalette.textPrimaryLight,
        side: BorderSide(color: ColorPalette.border),
        minimumSize: Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        textStyle: TextStyles.button,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: ColorPalette.border,
      space: 1,
      thickness: 1,
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    textTheme: textTheme,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: ColorPalette.backgroundDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorPalette.surfaceDark,
      elevation: 0,
      iconTheme: IconThemeData(color: ColorPalette.textPrimaryDark),
      titleTextStyle: TextStyle(
        color: ColorPalette.textPrimaryDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Pretendard',
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: ColorPalette.primary,
      unselectedLabelColor: ColorPalette.textSecondaryDark,
      indicatorColor: ColorPalette.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyles.subtitle1,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ColorPalette.backgroundDark,
      selectedItemColor: ColorPalette.primary,
      unselectedItemColor: ColorPalette.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyles.caption,
      unselectedLabelStyle: TextStyles.caption,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radius),
      ),
      color: ColorPalette.surfaceDark,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorPalette.surfaceDark,
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
      contentPadding: EdgeInsets.all(Dimensions.padding),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        textStyle: TextStyles.button,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorPalette.primary,
        textStyle: TextStyles.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorPalette.textPrimaryDark,
        side: BorderSide(color: ColorPalette.borderDark),
        minimumSize: Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        textStyle: TextStyles.button,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: ColorPalette.borderDark,
      space: 1,
      thickness: 1,
    ),
  );
} 