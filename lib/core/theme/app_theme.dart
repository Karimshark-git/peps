import 'package:flutter/material.dart';
import 'color_palette.dart';
import 'text_styles.dart';

/// Global PEPS design system theme — dark glass
class AppTheme {
  static ThemeData get lightTheme {
    const baseScheme = ColorScheme.dark(
      primary: ColorPalette.gold,
      onPrimary: ColorPalette.buttonOnAccent,
      secondary: ColorPalette.blueAccent,
      onSecondary: ColorPalette.textPrimary,
      surface: ColorPalette.cardBackground,
      onSurface: ColorPalette.textPrimary,
      error: Colors.redAccent,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: ColorPalette.background,
      canvasColor: ColorPalette.background,
      cardTheme: CardThemeData(
        color: ColorPalette.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ColorPalette.cardBorder, width: 1),
        ),
        shadowColor: ColorPalette.shadowLight,
      ),
      dividerColor: ColorPalette.cardBorder,
      dividerTheme: const DividerThemeData(
        color: ColorPalette.cardBorder,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.gold,
          foregroundColor: ColorPalette.buttonOnAccent,
          disabledBackgroundColor: ColorPalette.gold.withValues(alpha: 0.35),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: ColorPalette.textPrimary),
        titleTextStyle: TextStyles.headingSmall,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorPalette.bottomNavBackground,
        selectedItemColor: ColorPalette.gold,
        unselectedItemColor: ColorPalette.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.cardBackground,
        hintStyle: TextStyles.placeholder,
        labelStyle: TextStyles.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColorPalette.cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColorPalette.cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColorPalette.gold, width: 1),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
