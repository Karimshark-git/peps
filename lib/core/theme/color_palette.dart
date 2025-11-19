import 'package:flutter/material.dart';

/// Global PEPS design system color palette
class ColorPalette {
  // Background
  static const Color background = Color(0xFFF8F3EC);
  
  // Card/Input background
  static const Color cardBackground = Color(0xFFF3EDE4);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2A2A2A);
  static const Color textSecondary = Color(0xFF7D7D7D);
  static const Color textPlaceholder = Color(0xFFB8B1A7);
  
  // Gold accents
  static const Color gold = Color(0xFFC8A96A);
  static const Color mutedGold = Color(0xFFDCC9A3);
  
  // Progress bar
  static const Color progressBackground = Color(0xFFE6DCCF);
  static const Color progressFill = Color(0xFFC8A96A);
  
  // Legacy support (keeping for backward compatibility)
  static const Color softBeige = Color(0xFFE8DCC4);
  static const Color cardBorder = Color(0xFFE5E5E5);
  static const Color cardBorderSelected = Color(0xFFC8A96A);
  
  // Shadow colors
  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.08);
  static Color shadowDark = Colors.black.withValues(alpha: 0.12);
}

