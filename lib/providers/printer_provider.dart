import 'package:flutter/material.dart';
import '../models/printer_model.dart';
import '../services/bluetooth_printer_service.dart';
import '../services/settings_service.dart';

class PrinterProvider extends ChangeNotifier {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  final SettingsService _settingsService = SettingsService();

  List<PrinterModel> _availablePrinters = [];
  PrinterModel? _connectedPrinter;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _error;

  // Getters
  List<PrinterModel> get availablePrinters => _availablePrinters;
  PrinterModel? get connectedPrinter => _connectedPrinter;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _connectedPrinter != null;
  String? get error => _error;
  BluetoothPrinterService get printerService => _printerService;

  /// Initialize - try to reconnect to last printer
  Future<void> init() async {
    final lastMac = await _settingsService.getLastPrinterMac();
    final lastName = await _settingsService.getLastPrinterName();

    if (lastMac != null && lastName != null) {
      // Try to auto-connect to last printer
      await scanForPrinters();

      final lastPrinter = _availablePrinters.firstWhere(
        (p) => p.address == lastMac,
        orElse: () => PrinterModel(name: lastName, address: lastMac),
      );

      if (_availablePrinters.contains(lastPrinter)) {
        await connectToPrinter(lastPrinter);
      }
    }
  }

  /// Scan for Bluetooth printers
  Future<void> scanForPrinters() async {
    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      _availablePrinters = await _printerService.scanDevices();
    } catch (e) {
      _error = 'Gagal scan printer: $e';
    }

    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a printer
  Future<bool> connectToPrinter(PrinterModel printer) async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _printerService.connect(printer);

      if (success) {
        _connectedPrinter = printer.copyWith(isConnected: true);
        await _settingsService.saveLastPrinter(printer.name, printer.address);

        // Update available printers list
        _availablePrinters = _availablePrinters.map((p) {
          return p.address == printer.address
              ? p.copyWith(isConnected: true)
              : p.copyWith(isConnected: false);
        }).toList();
      } else {
        _error = 'Gagal konek ke printer';
      }

      _isConnecting = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Error: $e';
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from current printer
  Future<void> disconnect() async {
    await _printerService.disconnect();
    _connectedPrinter = null;

    _availablePrinters = _availablePrinters.map((p) {
      return p.copyWith(isConnected: false);
    }).toList();

    notifyListeners();
  }

  /// Test print
  Future<bool> testPrint() async {
    if (!isConnected) return false;
    return await _printerService.printTestPage();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _printerService.dispose();
    super.dispose();
  }
}
