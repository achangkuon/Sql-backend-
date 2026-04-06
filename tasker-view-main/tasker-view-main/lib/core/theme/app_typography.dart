import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Architectural Editorial Typography System
  // Font: Inter Medium (500) only.

  // Display Scale
  static TextStyle displayLG = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 1.1,
    letterSpacing: -0.02 * 48,
  );

  static TextStyle displayMD = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 1.2,
    letterSpacing: -0.02 * 36,
  );

  static TextStyle displaySM = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 1.2,
    letterSpacing: -0.02 * 32,
  );

  // Headlines
  static TextStyle headline = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 1.3,
    letterSpacing: -0.02 * 24,
  );

  // Body Text
  static TextStyle bodyLG = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    height: 1.6,
  );

  static TextStyle bodyMD = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    height: 1.6,
  );

  static TextStyle bodySM = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
  );

  // Labels
  static TextStyle labelLG = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    letterSpacing: 0.1,
  );

  static TextStyle labelMD = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    letterSpacing: 0.5,
  );

  static TextStyle labelSM = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    letterSpacing: 0.5,
  );

  // Aliases for compatibility
  static TextStyle get titleMD => headline;
  static TextStyle get headlineSM => displaySM;
  static TextStyle get labelBold => labelLG;
}




