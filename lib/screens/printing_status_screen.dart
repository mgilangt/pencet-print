import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/printer_provider.dart';
import '../widgets/primary_button.dart';

enum PrintStatus {
  connecting,
  printing,
  success,
  failed,
}

class PrintingStatusScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final int paperSize;
  final int copies;
  final String fileName;

  const PrintingStatusScreen({
    super.key,
    required this.imageBytes,
    required this.paperSize,
    required this.copies,
    required this.fileName,
  });

  @override
  State<PrintingStatusScreen> createState() => _PrintingStatusScreenState();
}

class _PrintingStatusScreenState extends State<PrintingStatusScreen>
    with SingleTickerProviderStateMixin {
  PrintStatus _status = PrintStatus.connecting;
  int _progress = 0;
  String _statusMessage = 'Menghubungkan ke printer thermal...';
  bool _isCancelled = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startPrinting();
  }

  @override
  void dispose() {
    _isCancelled = true;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startPrinting() async {
    final printerProvider = context.read<PrinterProvider>();

    // Simulate connection phase
    await _simulateProgress(0, 30, 'Menghubungkan ke printer thermal...');
    if (_isCancelled) return;

    setState(() {
      _status = PrintStatus.printing;
      _statusMessage = 'Sedang mencetak...';
    });

    // Simulate printing phase
    await _simulateProgress(30, 80, 'Sedang mencetak...');
    if (_isCancelled) return;

    // Actual print
    bool success = false;
    for (int i = 0; i < widget.copies; i++) {
      if (_isCancelled) return;

      try {
        success = await printerProvider.printerService.printImage(
          widget.imageBytes,
          paperWidth: widget.paperSize,
        );

        if (!success) break;

        // Update progress for each copy
        final copyProgress = 80 + ((i + 1) / widget.copies * 20).toInt();
        setState(() => _progress = copyProgress);
      } catch (e) {
        success = false;
        break;
      }
    }

    if (_isCancelled) return;

    setState(() {
      if (success) {
        _status = PrintStatus.success;
        _progress = 100;
        _statusMessage = 'Berhasil dicetak!';
      } else {
        _status = PrintStatus.failed;
        _statusMessage = 'Gagal mencetak. Coba lagi.';
      }
    });

    _animationController.stop();
  }

  Future<void> _simulateProgress(int start, int end, String message) async {
    for (int i = start; i <= end; i++) {
      if (_isCancelled) return;
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          _progress = i;
          _statusMessage = message;
        });
      }
    }
  }

  void _cancelPrint() {
    _isCancelled = true;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'STATUS PRINTER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated printer icon
              _buildAnimatedPrinterIcon(),

              const SizedBox(height: 40),

              // Status text
              Text(
                _getStatusTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Progress section
              if (_status != PrintStatus.success &&
                  _status != PrintStatus.failed)
                _buildProgressSection(),

              if (_status == PrintStatus.success) _buildSuccessIcon(),

              if (_status == PrintStatus.failed) _buildFailedIcon(),

              const Spacer(),

              // Bottom button
              if (_status == PrintStatus.connecting ||
                  _status == PrintStatus.printing)
                SecondaryButton(
                  text: 'Batalkan',
                  icon: Icons.close_rounded,
                  onPressed: _cancelPrint,
                )
              else if (_status == PrintStatus.success)
                PrimaryButton(
                  text: 'Selesai',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                )
              else
                Column(
                  children: [
                    PrimaryButton(
                      text: 'Coba Lagi',
                      icon: Icons.refresh_rounded,
                      onPressed: () {
                        setState(() {
                          _status = PrintStatus.connecting;
                          _progress = 0;
                          _isCancelled = false;
                        });
                        _animationController.repeat();
                        _startPrinting();
                      },
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      text: 'Kembali',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusTitle() {
    switch (_status) {
      case PrintStatus.connecting:
        return 'Menghubungkan...';
      case PrintStatus.printing:
        return 'Sedang Mencetak...';
      case PrintStatus.success:
        return 'Berhasil!';
      case PrintStatus.failed:
        return 'Gagal Mencetak';
    }
  }

  Widget _buildAnimatedPrinterIcon() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress circle
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: _status == PrintStatus.success
                      ? 1.0
                      : _status == PrintStatus.failed
                          ? 0
                          : _progress / 100,
                  strokeWidth: 4,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _status == PrintStatus.failed
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              ),
              // Printer icon
              Icon(
                Icons.print_rounded,
                size: 56,
                color: _status == PrintStatus.success
                    ? AppColors.success
                    : _status == PrintStatus.failed
                        ? AppColors.error
                        : AppColors.primary.withOpacity(0.7),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Memproses',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$_progress%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress / 100,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        size: 48,
        color: AppColors.success,
      ),
    );
  }

  Widget _buildFailedIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.error_rounded,
        size: 48,
        color: AppColors.error,
      ),
    );
  }
}
