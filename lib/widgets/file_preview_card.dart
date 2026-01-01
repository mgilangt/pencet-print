import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class FilePreviewCard extends StatelessWidget {
  final String fileName;
  final String? filePath;
  final int? fileSize;
  final String? addedTime;
  final VoidCallback? onChangeTap;

  const FilePreviewCard({
    super.key,
    required this.fileName,
    this.filePath,
    this.fileSize,
    this.addedTime,
    this.onChangeTap,
  });

  String get _formattedSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get _isImage {
    final ext = fileName.toLowerCase();
    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg');
  }

  bool get _isPdf => fileName.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // File icon/thumbnail
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isPdf
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isImage && filePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(filePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultIcon(),
                    ),
                  )
                : _buildDefaultIcon(),
          ),
          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formattedSize}${addedTime != null ? ' • $addedTime' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Change button
          if (onChangeTap != null)
            TextButton(
              onPressed: onChangeTap,
              child: const Text(
                'Ganti',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      _isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
      color: _isPdf ? Colors.red : AppColors.primary,
      size: 24,
    );
  }
}
