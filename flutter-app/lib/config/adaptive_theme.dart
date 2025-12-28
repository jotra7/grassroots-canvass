import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Centralized theme configuration for platform-adaptive styling.
/// Contains both Material and Cupertino theme definitions.
class AdaptiveTheme {
  // Default brand colors - can be customized per campaign
  static const Color primaryOrange = Color(0xFFDE6D48);
  static const Color darkOrange = Color(0xFFC9512D);
  static const Color sageGreen = Color(0xFF587758);
  static const Color darkBackground = Color(0xFF1E2328);
  static const Color warmTan = Color(0xFFD0C1AA);

  // Light theme surface colors
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Color(0xFF1E2328);
  static const Color lightSurfaceContainer = Color(0xFFF5F3F0);

  // Dark theme surface colors
  static const Color darkSurface = Color(0xFF1E2328);
  static const Color darkOnSurface = Color(0xFFE8E6E3);
  static const Color darkSurfaceContainer = Color(0xFF2A2F35);

  /// Material light theme
  static ThemeData get lightMaterial => ThemeData(
        colorScheme: ColorScheme.light(
          primary: primaryOrange,
          onPrimary: Colors.white,
          primaryContainer: primaryOrange.withValues(alpha: 0.15),
          onPrimaryContainer: darkOrange,
          secondary: sageGreen,
          onSecondary: Colors.white,
          secondaryContainer: sageGreen.withValues(alpha: 0.15),
          onSecondaryContainer: sageGreen,
          surface: lightSurface,
          onSurface: lightOnSurface,
          surfaceContainerHighest: lightSurfaceContainer,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryOrange, width: 2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
          ),
        ),
      );

  /// Material dark theme
  static ThemeData get darkMaterial => ThemeData(
        colorScheme: ColorScheme.dark(
          primary: primaryOrange,
          onPrimary: Colors.white,
          primaryContainer: primaryOrange.withValues(alpha: 0.25),
          onPrimaryContainer: const Color(0xFFFBEAE3),
          secondary: sageGreen,
          onSecondary: Colors.white,
          secondaryContainer: sageGreen.withValues(alpha: 0.25),
          onSecondaryContainer: const Color(0xFFC9D7C9),
          surface: darkSurface,
          onSurface: darkOnSurface,
          surfaceContainerHighest: darkSurfaceContainer,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: darkBackground,
          foregroundColor: primaryOrange,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryOrange, width: 2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
          ),
        ),
      );

  /// Cupertino light theme
  static CupertinoThemeData get lightCupertino => const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: primaryOrange,
        primaryContrastingColor: Colors.white,
        barBackgroundColor: CupertinoColors.systemBackground,
        scaffoldBackgroundColor: CupertinoColors.systemBackground,
        textTheme: CupertinoTextThemeData(
          primaryColor: primaryOrange,
        ),
      );

  /// Cupertino dark theme
  static CupertinoThemeData get darkCupertino => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryOrange,
        primaryContrastingColor: Colors.white,
        barBackgroundColor: darkBackground,
        scaffoldBackgroundColor: darkBackground,
        textTheme: CupertinoTextThemeData(
          primaryColor: primaryOrange,
        ),
      );
}
