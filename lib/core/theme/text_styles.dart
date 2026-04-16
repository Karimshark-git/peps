import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';

/// PEPS typography — Sora + DM Mono
class TextStyles {
  static TextStyle headingLarge = GoogleFonts.sora(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle headingMedium = GoogleFonts.sora(
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: ColorPalette.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static TextStyle headingSmall = GoogleFonts.sora(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: ColorPalette.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static TextStyle bodyLarge = GoogleFonts.sora(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textPrimary,
    height: 1.55,
  );

  static TextStyle bodyMedium = GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textSecondary,
    height: 1.55,
  );

  static TextStyle bodySmall = GoogleFonts.sora(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textTertiary,
    height: 1.5,
  );

  static TextStyle labelMono = GoogleFonts.dmMono(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textTertiary,
    letterSpacing: 0.6,
  );

  static TextStyle sectionLabelMono = GoogleFonts.dmMono(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textTeal,
    letterSpacing: 0.6,
  );

  static TextStyle buttonText = GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorPalette.buttonOnAccent,
    letterSpacing: -0.2,
  );

  static TextStyle subtitle = GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textSecondary,
    height: 1.55,
  );

  static TextStyle placeholder = GoogleFonts.sora(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textPlaceholder,
    height: 1.55,
  );
}
