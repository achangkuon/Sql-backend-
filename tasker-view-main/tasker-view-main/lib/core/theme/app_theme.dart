import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.surfaceContainerLowest,
        surface: AppColors.background,
        onSurface: AppColors.onSurface,
        surfaceContainer: AppColors.surfaceContainerLowest,
        error: AppColors.error,
        secondary: AppColors.primaryDark,
      ),
      
      // Background and overall feel
      scaffoldBackgroundColor: AppColors.background,
      
      // Typography mapping
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLG,
        displayMedium: AppTypography.displayMD,
        displaySmall: AppTypography.displaySM,
        headlineMedium: AppTypography.headline,
        bodyLarge: AppTypography.bodyLG,
        bodyMedium: AppTypography.bodyMD,
        labelMedium: AppTypography.labelMD,
      ),
      
      // Card Design (Architectural Layering)
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      
      // Input Decoration (Tonal Layering)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Buttons (Premium feel with specific radius)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surfaceContainerLowest,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.labelLG,
        ),
      ),
    );
  }
}



