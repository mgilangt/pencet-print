import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../config/app_colors.dart';
import '../providers/printer_provider.dart';
import '../services/file_service.dart';
import 'print_document_screen.dart';
import 'printer_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileService _fileService = FileService();
  StreamSubscription? _intentDataStreamSubscription;
  List<SharedMediaFile>? _sharedFiles;

  @override
  void initState() {
    super.initState();
    // Initialize printer provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().init();
    });

    // Initialize sharing intent listener
    _initSharingListener();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  void _initSharingListener() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        setState(() {
          _sharedFiles = value;
        });
        _handleSharedFiles(value);
      },
      onError: (err) {
        debugPrint("getIntentDataStream error: $err");
      },
    );

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
      });
      _handleSharedFiles(value);
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    // Take the first file
    final file = files.first;

    // Create PlatformFile from SharedMediaFile
    final platformFile = PlatformFile(
      path: file.path,
      name: file.path.split('/').last,
      size: 0, // Size is not strictly required for file opening by path
      bytes: null,
      readStream: null,
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PrintDocumentScreen(file: platformFile),
        ),
      );
    }
  }

  Future<void> _pickFileAndNavigate() async {
    final file = await _fileService.pickFile();

    if (file != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PrintDocumentScreen(file: file),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pencet Print',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Show app info dialog
                      _showAppInfoDialog();
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 1. Cara Pakai
              _buildHelpCard(),

              const SizedBox(height: 16),

              // 2. Connect Printer card
              _buildConnectPrinterCard(),

              const SizedBox(height: 16),

              // 3. Main action card - Print Invoice
              _buildPrintInvoiceCard(),

              const Spacer(),

              // Bottom printer status
              _buildPrinterStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintInvoiceCard() {
    return GestureDetector(
      onTap: _pickFileAndNavigate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.print_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Print Invoice',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih PDF atau Gambar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ketuk untuk Mulai',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectPrinterCard() {
    return Consumer<PrinterProvider>(
      builder: (context, provider, _) {
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSetupScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: provider.isConnected
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.bluetooth_rounded,
                    color: provider.isConnected
                        ? AppColors.success
                        : AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isConnected
                            ? 'Printer Terhubung'
                            : 'Hubungkan Printer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.isConnected
                            ? provider.connectedPrinter!.name
                            : 'Bluetooth Setup & Config',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrinterStatusBar() {
    return Consumer<PrinterProvider>(
      builder: (context, provider, _) {
        if (!provider.isConnected) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${provider.connectedPrinter!.name} Connected',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.bluetooth_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cara Pakai'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Hubungkan printer Bluetooth terlebih dahulu'),
            SizedBox(height: 8),
            Text('2. Ketuk "Print Invoice" untuk pilih file'),
            SizedBox(height: 8),
            Text('3. Pilih ukuran kertas (58mm atau 80mm)'),
            SizedBox(height: 8),
            Text('4. Ketuk "PRINT INVOICE" untuk mencetak'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Tentang Aplikasi'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pencet Print',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Sekali Pencet, Langsung Print.'),
            SizedBox(height: 16),
            Text('Versi: 1.0.0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return InkWell(
      onTap: _showHelpDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cara Pakai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Panduan penggunaan aplikasi',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
