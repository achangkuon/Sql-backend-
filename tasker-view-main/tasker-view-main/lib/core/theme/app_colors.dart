import 'package:flutter/material.dart';

class AppColors {
  // Primary & Brand Authority
  static const Color primary = Color(0xFF1A6BFF);
  static const Color primaryDark = Color(0xFF0053D3);
  
  // Background & Surfaces
  static const Color background = Color(0xFFF8F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceLow = Color(0xFFF2F4F6); // Alias for surfaceContainerLow
  static const Color surfaceContainerHigh = Color(0xFFEBEDEF);
  static const Color surfaceContainerHighest = Color(0xFFE1E2E4);
  
  // Text & Content Hierarchy
  static const Color onSurface = Color(0xFF191C1E);
  static const Color textPrimary = Color(0xFF191C1E); // Alias for onSurface
  static const Color onSurfaceVariant = Color(0xFF424655);
  static const Color textSecondary = Color(0xFF424655); // Alias for onSurfaceVariant
  static const Color outlineVariant = Color(0xFFC2C6D8);
  
  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color alert = Color(0xFFF59E0B);
  static const Color warning = Color(0xFFF59E0B); // Alias for alert
  static const Color error = Color(0xFFEF4444);
  static const Color urgent = Color(0xFFEF4444); // Alias for error
  static const Color dispute = Color(0xFF7C3AED);
  static const Color verified = Color(0xFF1A6BFF);

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
    stops: [0.0, 1.0],
    transform: GradientRotation(2.356), // 135 degrees as per style guide
  );
}



