import 'package:flutter/material.dart';

/// Central colour tokens – sourced directly from the Figma design.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF135BEC);
  static const Color primaryLight = Color(0x1A135BEC); // 10% opacity
  static const Color primaryGlow = Color(0x4D135BEC); // 30% opacity

  static const Color dark = Color(0xFF0D121B);
  static const Color mid = Color(0xFF374151);
  static const Color muted = Color(0xFF6B7280);
  static const Color subtle = Color(0xFF9CA3AF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color surface = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);

  static const Color red = Color(0xFFEF4444);
  static const Color green = Color(0xFF22C55E);
  static const Color amber = Color(0xFFEAB308);

  // Additional colors for UI components
  static const Color backgroundDark = Color(0xFF0D121B); // same as dark
  static const Color textPrimary = Color(0xFF0D121B); // same as dark
  static const Color textSecondary = Color(0xFF6B7280); // same as muted
  static const Color primaryBlue = Color(0xFF135BEC); // same as primary
  static const Color chipBg = Color(0xFFF9FAFB); // same as surface

  /// Hero gradient – top-left → bottom-right
  static const List<Color> heroGradient = [
    Color(0xFF0B3DB8),
    Color(0xFF1A7AE8),
  ];
}
