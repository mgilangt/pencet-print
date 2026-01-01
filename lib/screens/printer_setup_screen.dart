import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/printer_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/paper_size_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/printer_card.dart';

class PrinterSetupScreen extends StatefulWidget {
  const PrinterSetupScreen({super.key});

  @override
  State<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends State<PrinterSetupScreen> {
  String? _selectedPrinterAddress;
  bool _showAllDevices = false;
  static const int _initialDeviceCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().init();
    });
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
    final printer = provider.availablePrinters.firstWhere(
      (p) => p.address == _selectedPrinterAddress,
    );

    final success = await provider.connectToPrinter(printer);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terhubung ke ${printer.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _testPrint() async {
    final provider = context.read<PrinterProvider>();

    if (!provider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hubungkan printer terlebih dahulu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = await provider.testPrint();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Test print berhasil!' : 'Test print gagal'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _saveSettings() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan disimpan'),
        backgroundColor: AppColors.success,
      ),
    );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Printer Setup'),
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
                      const Text(
                        'Status Koneksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildConnectionStatus(printerProvider),

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
                          const Text(
                            'Printer Tersedia',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
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
                        _buildEmptyPrinters()
                      else
                        _buildPrinterList(printerProvider),

                      const SizedBox(height: 24),

                      // Paper size - ONLY show when connected
                      if (printerProvider.isConnected) ...[
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
                              onChanged: (size) => settings.setPaperSize(size),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pilih 58mm untuk printer thermal standar kecil',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.border),
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
  }) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
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

  Widget _buildPrinterList(PrinterProvider printerProvider) {
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

  Widget _buildConnectionStatus(PrinterProvider provider) {
    final isConnected = provider.isConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
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
              color: isConnected ? AppColors.success : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isConnected
                ? provider.connectedPrinter!.name
                : 'Tidak ada printer aktif. Scan untuk menghubungkan.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrinters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.print_disabled_rounded,
            size: 48,
            color: AppColors.textLight,
          ),
          SizedBox(height: 12),
          Text(
            'Tidak ada printer ditemukan',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pastikan printer Bluetooth menyala\ndan berada dalam jangkauan',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
