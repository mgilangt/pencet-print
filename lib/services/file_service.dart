import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class FileService {
  /// Pick image or PDF file
  Future<PlatformFile?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
    } catch (e) {
      print('Error picking file: $e');
    }

    return null;
  }

  /// Read file bytes
  Future<Uint8List?> readFileBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print('Error reading file: $e');
    }

    return null;
  }

  /// Get file size in readable format
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
