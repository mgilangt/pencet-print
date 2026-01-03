import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_constants.dart';
import '../providers/theme_provider.dart';

class PaperSizeSelector extends StatelessWidget {
  final int selectedSize;
  final ValueChanged<int>? onChanged;
  final bool showLabels;

  const PaperSizeSelector({
    super.key,
    required this.selectedSize,
    this.onChanged,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Row(
      children: [
        Expanded(
          child: _PaperSizeCard(
            size: AppConstants.paperSize58mm,
            label: showLabels ? 'Receipt' : null,
            isSelected: selectedSize == AppConstants.paperSize58mm,
            onTap: () => onChanged?.call(AppConstants.paperSize58mm),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PaperSizeCard(
            size: AppConstants.paperSize80mm,
            label: showLabels ? 'Invoice' : null,
            isSelected: selectedSize == AppConstants.paperSize80mm,
            onTap: () => onChanged?.call(AppConstants.paperSize80mm),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _PaperSizeCard extends StatelessWidget {
  final int size;
  final String? label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDark;

  const _PaperSizeCard({
    required this.size,
    this.label,
    required this.isSelected,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorder(isDark),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.getTextSecondary(isDark),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              '${size}mm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.getTextPrimary(isDark),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.getTextSecondary(isDark),
                ),
              ),
            ],
            if (isSelected) ...[
              const SizedBox(height: 6),
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
