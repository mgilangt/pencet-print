import 'dart:typed_data';

enum PrintJobStatus {
  idle,
  preparing,
  connecting,
  printing,
  completed,
  failed,
  cancelled,
}

class PrintJobModel {
  final String fileName;
  final String filePath;
  final Uint8List? fileBytes;
  final int paperSize;
  final int copies;
  final PrintJobStatus status;
  final int progress;
  final String? errorMessage;
  final DateTime createdAt;

  const PrintJobModel({
    required this.fileName,
    required this.filePath,
    this.fileBytes,
    this.paperSize = 80,
    this.copies = 1,
    this.status = PrintJobStatus.idle,
    this.progress = 0,
    this.errorMessage,
    required this.createdAt,
  });

  PrintJobModel copyWith({
    String? fileName,
    String? filePath,
    Uint8List? fileBytes,
    int? paperSize,
    int? copies,
    PrintJobStatus? status,
    int? progress,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return PrintJobModel(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileBytes: fileBytes ?? this.fileBytes,
      paperSize: paperSize ?? this.paperSize,
      copies: copies ?? this.copies,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isImage {
    final ext = fileName.toLowerCase();
    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg');
  }

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');
}
