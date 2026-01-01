import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import '../config/app_colors.dart';
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/file_service.dart';
import '../widgets/file_preview_card.dart';
import '../widgets/paper_size_selector.dart';
import '../widgets/primary_button.dart';
import 'printing_status_screen.dart';
import 'printer_setup_screen.dart';

class PrintDocumentScreen extends StatefulWidget {
  final PlatformFile file;

  const PrintDocumentScreen({
    super.key,
    required this.file,
  });

  @override
  State<PrintDocumentScreen> createState() => _PrintDocumentScreenState();
}

class _PrintDocumentScreenState extends State<PrintDocumentScreen> {
  final FileService _fileService = FileService();

  late PlatformFile _currentFile;
  int _copies = 1;
  Uint8List? _previewBytes;
  bool _isLoadingPreview = true;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() => _isLoadingPreview = true);

    try {
      if (_currentFile.path != null) {
        if (_currentFile.extension?.toLowerCase() == 'pdf') {
          // Load PDF first page as preview
          final document = await PdfDocument.openFile(_currentFile.path!);
          final page = await document.getPage(1);
          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
          );
          _previewBytes = pageImage?.bytes;
          await page.close();
          await document.close();
        } else {
          // Load image directly
          _previewBytes = await _fileService.readFileBytes(_currentFile.path!);
        }
      }
    } catch (e) {
      debugPrint('Error loading preview: $e');
    }

    if (mounted) {
      setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _changeFile() async {
    final file = await _fileService.pickFile();
    if (file != null) {
      setState(() {
        _currentFile = file;
      });
      _loadPreview();
    }
  }

  void _navigateToPrint() {
    final printerProvider = context.read<PrinterProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (!printerProvider.isConnected) {
      // Show dialog to connect printer first
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Printer Belum Terhubung'),
            ],
          ),
          content: const Text(
              'Silakan hubungkan printer Bluetooth terlebih dahulu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrinterSetupScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Hubungkan Printer'),
            ),
          ],
        ),
      );
      return;
    }

    if (_previewBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File tidak bisa diproses')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrintingStatusScreen(
          imageBytes: _previewBytes!,
          paperSize: settingsProvider.paperSize,
          copies: _copies,
          fileName: _currentFile.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Print Document'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected file section
                  const Text(
                    'File Dipilih',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilePreviewCard(
                    fileName: _currentFile.name,
                    filePath: _currentFile.path,
                    fileSize: _currentFile.size,
                    addedTime: 'Baru saja',
                    onChangeTap: _changeFile,
                  ),

                  const SizedBox(height: 24),

                  // Preview section
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPreview(),

                  const SizedBox(height: 24),

                  // Printer settings section
                  const Text(
                    'Pengaturan Printer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPrinterDropdown(),

                  const SizedBox(height: 16),

                  // Paper size
                  const Text(
                    'Ukuran Kertas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return PaperSizeSelector(
                        selectedSize: settings.paperSize,
                        showLabels: false,
                        onChanged: (size) => settings.setPaperSize(size),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Copies
                  const Text(
                    'Jumlah Cetak',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCopiesCounter(),
                ],
              ),
            ),
          ),

          // Print button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: PrimaryButton(
              text: 'PRINT INVOICE',
              icon: Icons.print_rounded,
              onPressed: _navigateToPrint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isLoadingPreview
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _previewBytes != null
                ? Image.memory(
                    _previewBytes!,
                    fit: BoxFit.contain,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_rounded,
                            size: 48, color: AppColors.textLight),
                        SizedBox(height: 8),
                        Text('Preview tidak tersedia',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildPrinterDropdown() {
    return Consumer<PrinterProvider>(
      builder: (context, provider, _) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrinterSetupScreen()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.print_rounded,
                    color: provider.isConnected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isConnected
                            ? provider.connectedPrinter!.name
                            : 'Pilih Printer',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (provider.isConnected)
                        const Row(
                          children: [
                            Icon(Icons.circle,
                                color: AppColors.success, size: 8),
                            SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopiesCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.remove_rounded,
                color:
                    _copies > 1 ? AppColors.textPrimary : AppColors.textLight,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            '$_copies',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            onPressed: _copies < 10 ? () => setState(() => _copies++) : null,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                color:
                    _copies < 10 ? AppColors.textPrimary : AppColors.textLight,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
