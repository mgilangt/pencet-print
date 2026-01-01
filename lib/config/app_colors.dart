import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  
  // Primary blue theme (matching the mockups)
  static const Color primary = Color(0xFF2D7FF9);
  static const Color primaryLight = Color(0xFF5BA0FF);
  static const Color primaryDark = Color(0xFF1A5FD1);
  
  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
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
}
