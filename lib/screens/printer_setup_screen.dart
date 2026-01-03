import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/paper_size_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/printer_card.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/floating_toast.dart';

class PrinterSetupScreen extends StatefulWidget {
  const PrinterSetupScreen({super.key});

  @override
  State<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends State<PrinterSetupScreen>
    with WidgetsBindingObserver {
  String? _selectedPrinterAddress;
  bool _showAllDevices = false;
  static const int _initialDeviceCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().init();
      _verifyAndAutoReconnect();
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
      // App resumed - verify connection and auto-reconnect if needed
      _verifyAndAutoReconnect();
    }
  }

  /// Verify connection status when screen loads or resumes
  /// If Bluetooth is available but not connected, try to auto-reconnect
  Future<void> _verifyAndAutoReconnect() async {
    final provider = context.read<PrinterProvider>();

    // Check if Bluetooth is available
    final isBluetoothOn = await provider.printerService.isBluetoothAvailable();

    if (!isBluetoothOn) {
      // Bluetooth is still off - show alert
      if (mounted) {
        FloatingToast.error(context, 'Bluetooth tidak aktif',
            icon: Icons.bluetooth_disabled_rounded);
      }
      return;
    }

    if (provider.isConnected) {
      // Already marked as connected - verify it's still valid
      final isValid = await provider.verifyConnection();

      if (!isValid && mounted) {
        // Connection was stale - show alert and try to reconnect
        FloatingToast.loading(
            context, 'Koneksi terputus, menghubungkan ulang...');
        debugPrint(
            'PrinterSetupScreen: Connection stale, attempting auto-reconnect');
        await _tryAutoReconnect();
      }
    } else {
      // Not connected but Bluetooth is on - try to reconnect to last printer
      debugPrint('PrinterSetupScreen: Bluetooth on, attempting auto-reconnect');
      await _tryAutoReconnect();
    }
  }

  /// Try to auto-reconnect to the last used printer
  Future<void> _tryAutoReconnect() async {
    final provider = context.read<PrinterProvider>();

    // Auto-scan and reconnect
    await provider.verifyAndReconnect();

    if (mounted) {
      if (provider.isConnected) {
        FloatingToast.success(
            context, 'Terhubung ke ${provider.connectedPrinter!.name}');
      }
    }
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _showAllDevices = false;
    });
    await context.read<PrinterProvider>().scanForPrinters();
  }

  Future<void> _connectToSelectedPrinter() async {
    if (_selectedPrinterAddress == null) return;

    final provider = context.read<PrinterProvider>();

    // First disconnect any existing connection to ensure clean state
    if (provider.isConnected) {
      await provider.disconnect();
    }

    final printer = provider.availablePrinters.firstWhere(
      (p) => p.address == _selectedPrinterAddress,
    );

    final success = await provider.connectToPrinter(printer);

    if (mounted) {
      if (success) {
        FloatingToast.success(context, 'Terhubung ke ${printer.name}');
      } else {
        FloatingToast.error(
            context, 'Gagal terhubung ke ${printer.name}. Coba lagi.');
      }
    }
  }

  Future<void> _testPrint() async {
    final provider = context.read<PrinterProvider>();

    // Verify actual connection first (not just variable state)
    final isConnectionValid = await provider.verifyConnection();

    if (!provider.isConnected || !isConnectionValid) {
      if (!mounted) return;

      // Check if Bluetooth is off
      final isBluetoothOn =
          await provider.printerService.isBluetoothAvailable();

      if (!isBluetoothOn) {
        CustomDialog.showError(
          context: context,
          title: 'Bluetooth Tidak Aktif!',
          message: 'Nyalakan Bluetooth di HP Anda untuk melanjutkan.',
          primaryButtonText: 'Mengerti',
          secondaryButtonText: null,
          onPrimaryPressed: () => Navigator.pop(context),
        );
      } else {
        CustomDialog.showWarning(
          context: context,
          title: 'Printer Tidak Terhubung!',
          message: 'Koneksi terputus. Scan dan hubungkan ulang printer.',
          primaryButtonText: 'Scan Ulang',
          primaryButtonIcon: Icons.search_rounded,
          secondaryButtonText: 'Batalkan',
          onPrimaryPressed: () {
            Navigator.pop(context);
            _scanPrinters();
          },
          onSecondaryPressed: () => Navigator.pop(context),
        );
      }
      return;
    }

    // Try to print
    final success = await provider.testPrint();

    if (mounted) {
      if (success) {
        CustomDialog.showSuccess(
          context: context,
          title: 'Cetak Berhasil!',
          message: 'Struk test sudah dicetak.',
          buttonText: 'OK',
        );
      } else {
        // Print failed - mark as disconnected and offer to reconnect
        await provider.disconnect();

        CustomDialog.showError(
          context: context,
          title: 'Cetak Gagal',
          message: 'Koneksi printer terputus. Coba hubungkan ulang.',
          primaryButtonText: 'Hubungkan Ulang',
          secondaryButtonText: 'Batalkan',
          onPrimaryPressed: () async {
            Navigator.pop(context);
            // Try to reconnect automatically
            await _autoReconnect();
          },
          onSecondaryPressed: () => Navigator.pop(context),
        );
      }
    }
  }

  /// Try to auto-reconnect to last used printer
  Future<void> _autoReconnect() async {
    final provider = context.read<PrinterProvider>();

    // Scan first
    await _scanPrinters();

    // Try to reconnect
    await provider.verifyAndReconnect();

    if (mounted && provider.isConnected) {
      FloatingToast.success(
          context, 'Terhubung ke ${provider.connectedPrinter!.name}');
    }
  }

  void _saveSettings() {
    FloatingToast.success(context, 'Pengaturan disimpan',
        icon: Icons.save_rounded);
    Navigator.pop(context);
  }

  List<dynamic> _sortDevices(List<dynamic> devices, String? lastUsedAddress) {
    final printerKeywords = [
      'print',
      'mpt',
      'pos',
      'thermal',
      'receipt',
      'pt-',
      'rpp'
    ];

    return List.from(devices)
      ..sort((a, b) {
        final aName = a.name.toString().toLowerCase();
        final bName = b.name.toString().toLowerCase();

        if (a.address == lastUsedAddress) return -1;
        if (b.address == lastUsedAddress) return 1;

        final aIsPrinter = printerKeywords.any((k) => aName.contains(k));
        final bIsPrinter = printerKeywords.any((k) => bName.contains(k));

        if (aIsPrinter && !bIsPrinter) return -1;
        if (bIsPrinter && !aIsPrinter) return 1;

        return 0;
      });
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
          'Printer Setup',
          style: TextStyle(color: AppColors.getTextPrimary(isDark)),
        ),
        centerTitle: true,
      ),
      body: Consumer<PrinterProvider>(
        builder: (context, printerProvider, _) {
          return Stack(
            children: [
              // Scrollable content
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Connection Status
                      Text(
                        'Status Koneksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildConnectionStatus(printerProvider, isDark),

                      const SizedBox(height: 24),

                      // Scan button
                      PrimaryButton(
                        text: printerProvider.isScanning
                            ? 'Mencari...'
                            : 'Cari Printer',
                        icon: Icons.search_rounded,
                        isLoading: printerProvider.isScanning,
                        onPressed:
                            printerProvider.isScanning ? null : _scanPrinters,
                      ),

                      const SizedBox(height: 24),

                      // Available printers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Printer Tersedia',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextSecondary(isDark),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _scanPrinters,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Refresh'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (printerProvider.availablePrinters.isEmpty)
                        _buildEmptyPrinters(isDark)
                      else
                        _buildPrinterList(printerProvider, isDark),

                      const SizedBox(height: 24),

                      // Paper size - ONLY show when connected
                      if (printerProvider.isConnected) ...[
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
                              onChanged: (size) => settings.setPaperSize(size),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pilih 58mm untuk printer thermal standar kecil',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextLight(isDark),
                          ),
                        ),
                      ],

                      // Add some bottom padding for the sticky buttons
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Sticky bottom buttons
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(isDark),
                    border: Border(
                      top: BorderSide(color: AppColors.getBorder(isDark)),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Test Print button (left) - only show when connected
                        if (printerProvider.isConnected)
                          Expanded(
                            child: _buildOutlinedButton(
                              text: 'Test Print',
                              icon: Icons.print_rounded,
                              onPressed: _testPrint,
                              isDark: isDark,
                            ),
                          ),

                        if (printerProvider.isConnected)
                          const SizedBox(width: 12),

                        // Simpan button (right or full width)
                        Expanded(
                          child: PrimaryButton(
                            text: 'Simpan',
                            icon: Icons.save_rounded,
                            onPressed: _saveSettings,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.getCardBackground(isDark),
          foregroundColor: AppColors.getTextPrimary(isDark),
          side: BorderSide(color: AppColors.getBorder(isDark), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.getTextSecondary(isDark)),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterList(PrinterProvider printerProvider, bool isDark) {
    final sortedDevices = _sortDevices(
      printerProvider.availablePrinters,
      printerProvider.connectedPrinter?.address,
    );

    final displayCount = _showAllDevices
        ? sortedDevices.length
        : sortedDevices.length > _initialDeviceCount
            ? _initialDeviceCount
            : sortedDevices.length;

    final displayDevices = sortedDevices.take(displayCount).toList();
    final hasMore = sortedDevices.length > _initialDeviceCount;

    return Column(
      children: [
        ...displayDevices.map((printer) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PrinterCard(
              printer: printer,
              isSelected: _selectedPrinterAddress == printer.address,
              onTap: () {
                setState(() {
                  _selectedPrinterAddress = printer.address;
                });
                if (!printer.isConnected) {
                  _connectToSelectedPrinter();
                }
              },
            ),
          );
        }),

        // Load more / Show less button
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllDevices = !_showAllDevices;
                });
              },
              child: Text(
                _showAllDevices
                    ? 'Tampilkan lebih sedikit'
                    : 'Tampilkan ${sortedDevices.length - _initialDeviceCount} perangkat lainnya',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionStatus(PrinterProvider provider, bool isDark) {
    final isConnected = provider.isConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnected
                  ? Icons.bluetooth_connected_rounded
                  : Icons.bluetooth_disabled_rounded,
              size: 32,
              color: isConnected ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isConnected ? 'Terhubung' : 'Tidak Terhubung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isConnected
                  ? AppColors.success
                  : AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isConnected
                ? provider.connectedPrinter!.name
                : 'Tidak ada printer aktif. Scan untuk menghubungkan.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrinters(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.print_disabled_rounded,
            size: 48,
            color: AppColors.getTextLight(isDark),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada printer ditemukan',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan printer Bluetooth menyala\ndan berada dalam jangkauan',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextLight(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
