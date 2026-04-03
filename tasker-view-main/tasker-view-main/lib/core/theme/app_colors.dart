import 'package:flutter/material.dart';

class AppColors {
  // Primary & Brand Authority
  static const Color primary = Color(0xFF1A6BFF);
  static const Color primaryDark = Color(0xFF0053D3);

  // Surface Philosophy (Architectural Layering)
  static const Color surface = Color(0xFFF7F8FA); // Base
  static const Color surfaceLow = Color(0xFFEFF1F5); // Sectioning
  static const Color surfaceLowest = Color(0xFFFFFFFF); // Cards
  
  // Style Guide EXACT implementations
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainerHigh = Color(0xFFEBEBEB); // Intermedio
  static const Color surfaceContainerHighest = Color(0xFFE1E2E4);
  
  // Interaction & Informational
  static const Color surfaceVariant = Color(0xFFE8F0FF); // Chips/Accents
  static const Color outlineVariant = Color(0xFFC2C6D8); // Ghost border
  
  // Status Colors
  static const Color urgent = Color(0xFFFF5C3A); // Tertiary
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFBA1A1A);

  // Typography
  static const Color textPrimary = Color(0xFF0D0F1A);
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}
