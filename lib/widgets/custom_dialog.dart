import 'package:flutter/material.dart';
import '../config/app_colors.dart';

enum DialogType {
  success,
  error,
  warning,
}

class CustomDialog extends StatelessWidget {
  final DialogType type;
  final String title;
  final String message;
  final String primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final IconData? primaryButtonIcon;

  const CustomDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.primaryButtonIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            _buildIcon(),

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Primary Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onPrimaryPressed ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (primaryButtonIcon != null) ...[
                      Icon(primaryButtonIcon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      primaryButtonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Secondary Button
            if (secondaryButtonText != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    secondaryButtonText!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case DialogType.success:
        bgColor = AppColors.success.withOpacity(0.1);
        iconColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case DialogType.error:
        bgColor = AppColors.error.withOpacity(0.1);
        iconColor = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      case DialogType.warning:
        bgColor = AppColors.warning.withOpacity(0.1);
        iconColor = AppColors.warning;
        icon = Icons.warning_rounded;
        break;
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 40,
        color: iconColor,
      ),
    );
  }

  /// Show success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        type: DialogType.success,
        title: title,
        message: message,
        primaryButtonText: buttonText,
        onPrimaryPressed: onPressed ?? () => Navigator.pop(context),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String primaryButtonText = 'Coba Lagi',
    String? secondaryButtonText = 'Batalkan',
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        type: DialogType.error,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed ?? () => Navigator.pop(context),
      ),
    );
  }

  /// Show warning dialog (printer not connected)
  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String primaryButtonText = 'Mengerti',
    String? secondaryButtonText = 'Cek Pengaturan',
    IconData? primaryButtonIcon = Icons.check_rounded,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        type: DialogType.warning,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        primaryButtonIcon: primaryButtonIcon,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed ?? () => Navigator.pop(context),
        onSecondaryPressed: onSecondaryPressed,
      ),
    );
  }
}
