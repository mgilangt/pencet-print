import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary blue theme (matching the mockups)
  static const Color primary = Color(0xFF2D7FF9);
  static const Color primaryLight = Color(0xFF5BA0FF);
  static const Color primaryDark = Color(0xFF1A5FD1);

  // Light mode colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Dark mode colors
  static const Color backgroundDark = Color(0xFF121218);
  static const Color cardBackgroundDark = Color(0xFF1E1E2D);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
  static const Color textLightDark = Color(0xFF6B6B6B);
  static const Color borderDark = Color(0xFF2D2D3A);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D7FF9), Color(0xFF5BA0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border
  static const Color border = Color(0xFFE5E7EB);

  // Helper methods for theme-aware colors
  static Color getBackground(bool isDark) =>
      isDark ? backgroundDark : background;
  static Color getCardBackground(bool isDark) =>
      isDark ? cardBackgroundDark : cardBackground;
  static Color getTextPrimary(bool isDark) =>
      isDark ? textPrimaryDark : textPrimary;
  static Color getTextSecondary(bool isDark) =>
      isDark ? textSecondaryDark : textSecondary;
  static Color getTextLight(bool isDark) => isDark ? textLightDark : textLight;
  static Color getBorder(bool isDark) => isDark ? borderDark : border;
}
