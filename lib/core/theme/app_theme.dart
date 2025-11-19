import 'package:flutter/material.dart';
import 'color_palette.dart';
import 'text_styles.dart';

/// Luxury wellness theme for PEPS app
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: ColorPalette.gold,
        secondary: ColorPalette.softBeige,
        surface: ColorPalette.cardBackground,
        onPrimary: Colors.white,
        onSecondary: ColorPalette.textPrimary,
        onSurface: ColorPalette.textPrimary,
      ),
      scaffoldBackgroundColor: ColorPalette.background,
      cardTheme: CardThemeData(
        color: ColorPalette.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: ColorPalette.shadowLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.gold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyles.buttonText,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyles.headingLarge,
        displayMedium: TextStyles.headingMedium,
        displaySmall: TextStyles.headingSmall,
        bodyLarge: TextStyles.bodyLarge,
        bodyMedium: TextStyles.bodyMedium,
        bodySmall: TextStyles.bodySmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorPalette.textPrimary),
        titleTextStyle: TextStyles.headingSmall,
      ),
    );
  }
}

