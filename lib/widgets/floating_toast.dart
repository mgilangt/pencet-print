import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Floating toast notification utility
/// Use [FloatingToast.show] to display a floating toast notification
class FloatingToast {
  /// Show a success toast (green)
  static void success(BuildContext context, String message, {IconData? icon}) {
    _show(
      context: context,
      message: message,
      icon: icon ?? Icons.check_circle_rounded,
      backgroundColor: AppColors.success,
    );
  }

  /// Show an error toast (red)
  static void error(BuildContext context, String message, {IconData? icon}) {
    _show(
      context: context,
      message: message,
      icon: icon ?? Icons.error_rounded,
      backgroundColor: AppColors.error,
    );
  }

  /// Show a warning toast (orange)
  static void warning(BuildContext context, String message, {IconData? icon}) {
    _show(
      context: context,
      message: message,
      icon: icon ?? Icons.warning_rounded,
      backgroundColor: AppColors.warning,
    );
  }

  /// Show an info toast (blue)
  static void info(BuildContext context, String message, {IconData? icon}) {
    _show(
      context: context,
      message: message,
      icon: icon ?? Icons.info_rounded,
      backgroundColor: AppColors.primary,
    );
  }

  /// Show a loading toast (blue with sync icon)
  static void loading(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.sync_rounded,
      backgroundColor: AppColors.primary,
    );
  }

  /// Internal show method
  static void _show({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 8,
        duration: duration,
      ),
    );
  }

  /// Dismiss any active toast
  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
