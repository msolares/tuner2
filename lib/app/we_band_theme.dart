import 'package:flutter/material.dart';

class WeBandTheme {
  WeBandTheme._();

  static const Color background = Color(0xFF08090C);
  static const Color backgroundElevated = Color(0xFF12151C);
  static const Color surface = Color(0xFF171B23);
  static const Color surfaceStrong = Color(0xFF212632);
  static const Color outline = Color(0xFF2C3340);
  static const Color outlineMuted = Color(0xFF232935);
  static const Color textPrimary = Color(0xFFF5F7FB);
  static const Color textSecondary = Color(0xFFA9B0BC);
  static const Color textMuted = Color(0xFF737B89);
  static const Color brandRed = Color(0xFFFF2750);
  static const Color brandRedDeep = Color(0xFFAB102E);
  static const Color tuneGreen = Color(0xFF1CDA97);
  static const Color tuneAmber = Color(0xFFFFB347);
  static const Color tuneBlue = Color(0xFF4DA5FF);
  static const Color danger = Color(0xFFFF6B7E);

  static ThemeData theme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'BarlowCondensed',
    );
    final textTheme = base.textTheme.apply(
      fontFamily: 'BarlowCondensed',
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      colorScheme: const ColorScheme.dark(
        primary: brandRed,
        secondary: tuneGreen,
        surface: surface,
        error: danger,
        onPrimary: textPrimary,
        onSecondary: background,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      dividerColor: outlineMuted,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.8,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceStrong.withOpacity(0.82),
        labelStyle:
            const TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
        hintStyle:
            const TextStyle(color: textMuted, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: brandRed, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: brandRed,
        inactiveTrackColor: outline,
        thumbColor: textPrimary,
        overlayColor: brandRed.withOpacity(0.14),
        trackHeight: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.8,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandRed,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandRed,
        foregroundColor: textPrimary,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: textSecondary,
        collapsedIconColor: textSecondary,
        textColor: textPrimary,
        collapsedTextColor: textPrimary,
      ),
    );
  }
}
