import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';

/// Text styles for PEPS app using luxury wellness aesthetic
class TextStyles {
  // Headings - Playfair Display
  static TextStyle headingLarge = GoogleFonts.playfairDisplay(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: ColorPalette.textPrimary,
    height: 1.2,
  );
  
  static TextStyle headingMedium = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
    height: 1.3,
  );
  
  static TextStyle headingSmall = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: ColorPalette.textPrimary,
    height: 1.3,
  );
  
  // Body text - Inter
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textPrimary,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textPrimary,
    height: 1.5,
  );
  
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textSecondary,
    height: 1.5,
  );
  
  // Button text
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // Subtitle
  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ColorPalette.textSecondary,
    height: 1.5,
  );
}

