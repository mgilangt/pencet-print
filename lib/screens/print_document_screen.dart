import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import '../config/app_colors.dart';
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/file_service.dart';
import '../widgets/file_preview_card.dart';
import '../widgets/paper_size_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/floating_toast.dart';
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

class _PrintDocumentScreenState extends State<PrintDocumentScreen>
    with WidgetsBindingObserver {
  final FileService _fileService = FileService();

  late PlatformFile _currentFile;
  int _copies = 1;
  Uint8List? _previewBytes;
  bool _isLoadingPreview = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentFile = widget.file;
    _loadPreview();

    // Reload settings to ensure paper size is correct
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().reload();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App resumed - verify and auto-reconnect if needed
      _verifyAndAutoReconnect();
    }
  }

  /// Verify connection and auto-reconnect when BT turns back on
  Future<void> _verifyAndAutoReconnect() async {
    final provider = context.read<PrinterProvider>();
    final isBluetoothOn = await provider.printerService.isBluetoothAvailable();

    if (!isBluetoothOn) return;

    // Reload settings first
    await context.read<SettingsProvider>().reload();

    // Check connection
    if (provider.isConnected) {
      final isValid = await provider.verifyConnection();
      if (!isValid && mounted) {
        FloatingToast.loading(context, 'Menghubungkan ulang printer...');
        await provider.verifyAndReconnect();

        if (mounted && provider.isConnected) {
          FloatingToast.success(
              context, 'Terhubung ke ${provider.connectedPrinter!.name}');
        }
      }
    } else {
      // Try to reconnect
      await provider.verifyAndReconnect();
      if (mounted && provider.isConnected) {
        FloatingToast.success(
            context, 'Terhubung ke ${provider.connectedPrinter!.name}');
      }
    }
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

  Future<void> _navigateToPrint() async {
    final printerProvider = context.read<PrinterProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // Reload settings to ensure we have the latest paper size
    await settingsProvider.reload();

    // Verify actual Bluetooth connection (not just variable state)
    final isConnectionValid = await printerProvider.verifyConnection();

    if (!printerProvider.isConnected || !isConnectionValid) {
      if (!mounted) return;
      // Show warning dialog
      CustomDialog.showWarning(
        context: context,
        title: 'Printer Tidak Terhubung!',
        message:
            'Koneksi terputus. Pastikan printer menyala dan bluetooth di HP Anda sudah aktif.',
        primaryButtonText: 'Mengerti',
        primaryButtonIcon: Icons.check_rounded,
        secondaryButtonText: 'Cek Pengaturan',
        onPrimaryPressed: () => Navigator.pop(context),
        onSecondaryPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrinterSetupScreen()),
          );
        },
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
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getCardBackground(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.getTextPrimary(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Print Document',
          style: TextStyle(color: AppColors.getTextPrimary(isDark)),
        ),
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
                  Text(
                    'File Dipilih',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(isDark),
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
                  Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPreview(isDark),

                  const SizedBox(height: 24),

                  // Printer settings section
                  Text(
                    'Pengaturan Printer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPrinterDropdown(isDark),

                  const SizedBox(height: 16),

                  // Paper size
                  Text(
                    'Ukuran Kertas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(isDark),
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
                  Text(
                    'Jumlah Cetak',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCopiesCounter(isDark),
                ],
              ),
            ),
          ),

          // Print button
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(isDark),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: PrimaryButton(
                text: 'PRINT',
                icon: Icons.print_rounded,
                onPressed: _navigateToPrint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(bool isDark) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
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
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_rounded,
                            size: 48, color: AppColors.getTextLight(isDark)),
                        const SizedBox(height: 8),
                        Text('Preview tidak tersedia',
                            style: TextStyle(
                                color: AppColors.getTextSecondary(isDark))),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildPrinterDropdown(bool isDark) {
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
              color: AppColors.getCardBackground(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getBorder(isDark)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.getBackground(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.print_rounded,
                    color: provider.isConnected
                        ? AppColors.primary
                        : AppColors.getTextSecondary(isDark),
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(isDark),
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
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopiesCounter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getBackground(isDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.remove_rounded,
                color: _copies > 1
                    ? AppColors.getTextPrimary(isDark)
                    : AppColors.getTextLight(isDark),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            '$_copies',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            onPressed: _copies < 10 ? () => setState(() => _copies++) : null,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getBackground(isDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                color: _copies < 10
                    ? AppColors.getTextPrimary(isDark)
                    : AppColors.getTextLight(isDark),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
