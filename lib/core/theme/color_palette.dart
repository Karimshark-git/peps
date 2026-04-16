import 'package:flutter/material.dart';

/// PEPS dark glass design system — clinical-tech palette
class ColorPalette {
  static const Color background = Color(0xFF08101E);

  /// Surface / card (opaque fallback for rgba(255,255,255,0.05))
  static const Color cardBackground = Color(0xFF0D1825);
  static const Color surfaceCard = Color(0xFF0D1825);

  /// Card borders (rgba white approximations)
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color cardBorderHi = Color(0x29FFFFFF);

  /// Primary accent (teal) — `gold` kept for backward compatibility
  static const Color gold = Color(0xFF3ECFA0);
  static const Color accent = Color(0xFF3ECFA0);
  static const Color accentDim = Color(0x1F3ECFA0);
  static const Color accentBorder = Color(0x473ECFA0);

  static const Color mutedGold = Color(0x473ECFA0);

  /// Secondary accent (blue)
  static const Color blueAccent = Color(0xFF7AABFF);
  static const Color blueDim = Color(0x1A6496FF);
  static const Color blueBorder = Color(0x386496FF);

  /// Text
  static const Color textPrimary = Color(0xE6FFFFFF);
  static const Color textSecondary = Color(0x8CFFFFFF);
  static const Color textTertiary = Color(0x4DFFFFFF);
  static const Color textTeal = Color(0xFF3ECFA0);

  /// Legacy alias — maps to tertiary muted text
  static const Color textPlaceholder = Color(0x4DFFFFFF);

  /// Progress
  static const Color progressBackground = Color(0x1AFFFFFF);
  static const Color progressFill = Color(0xFF3ECFA0);

  /// CTA text on teal buttons
  static const Color buttonOnAccent = Color(0xFF04201A);

  /// Bottom navigation shell
  static const Color bottomNavBackground = Color(0xFF0A1628);

  /// Legacy — warm neutrals remapped to dark surfaces
  static const Color softBeige = Color(0xFF0D1825);
  static const Color cardBorderSelected = Color(0x473ECFA0);

  static Color shadowLight = Colors.black.withValues(alpha: 0.4);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.4);
  static Color shadowDark = Colors.black.withValues(alpha: 0.4);
}
