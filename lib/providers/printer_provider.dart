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
  bool _isReconnecting = false; // Mutex to prevent concurrent reconnects
  bool _isInitialized = false;
  String? _error;

  // Getters
  List<PrinterModel> get availablePrinters => _availablePrinters;
  PrinterModel? get connectedPrinter => _connectedPrinter;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isReconnecting => _isReconnecting;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  BluetoothPrinterService get printerService => _printerService;

  /// Check if printer is connected (variable state only)
  bool get isConnected => _connectedPrinter != null;

  /// Initialize - try to reconnect to last printer
  Future<void> init() async {
    if (_isInitialized) return; // Prevent double init

    final lastMac = await _settingsService.getLastPrinterMac();
    final lastName = await _settingsService.getLastPrinterName();

    if (lastMac != null && lastName != null) {
      // Try to auto-connect to last printer
      await scanForPrinters();

      final lastPrinter = _availablePrinters.firstWhere(
        (p) => p.address == lastMac,
        orElse: () => PrinterModel(name: lastName, address: lastMac),
      );

      if (_availablePrinters.any((p) => p.address == lastMac)) {
        await connectToPrinter(lastPrinter);
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Verify if the current connection is still valid
  /// Returns true if connected and Bluetooth is available
  Future<bool> verifyConnection() async {
    if (_connectedPrinter == null) return false;

    // Check if Bluetooth is still on
    final bluetoothOn = await _printerService.isBluetoothAvailable();
    if (!bluetoothOn) {
      debugPrint('PrinterProvider: Bluetooth is off, marking as disconnected');
      await _markDisconnected();
      return false;
    }

    // Connection appears valid
    return true;
  }

  /// Force check and potentially reconnect to last printer
  /// Use this when app resumes from background or after Bluetooth toggle
  Future<void> verifyAndReconnect() async {
    // Prevent concurrent reconnection attempts
    if (_isReconnecting) {
      debugPrint('PrinterProvider: Reconnection already in progress, skipping');
      return;
    }

    final lastMac = await _settingsService.getLastPrinterMac();
    final lastName = await _settingsService.getLastPrinterName();

    if (lastMac == null || lastName == null) {
      // No saved printer to reconnect to
      return;
    }

    // Check if current connection is valid
    bool needsReconnect = false;

    if (_connectedPrinter != null) {
      final isValid = await verifyConnection();
      needsReconnect = !isValid;
    } else {
      // Not connected, try to connect
      needsReconnect = true;
    }

    if (needsReconnect) {
      _isReconnecting = true;
      notifyListeners();

      debugPrint('PrinterProvider: Reconnecting to $lastName');

      // Force disconnect to clear any stale state
      try {
        await _printerService.disconnect();
      } catch (_) {}

      // Clear local state
      _connectedPrinter = null;
      _availablePrinters = _availablePrinters
          .map((p) => p.copyWith(isConnected: false))
          .toList();
      notifyListeners();

      // Wait for Bluetooth stack to be fully ready
      await Future.delayed(const Duration(milliseconds: 800));

      // Scan for printers
      await scanForPrinters();

      // Find and connect to last printer
      if (_availablePrinters.any((p) => p.address == lastMac)) {
        final lastPrinter = _availablePrinters.firstWhere(
          (p) => p.address == lastMac,
        );
        await connectToPrinter(lastPrinter);
      } else {
        debugPrint('PrinterProvider: Last printer $lastName not found in scan');
      }

      _isReconnecting = false;
      notifyListeners();
    }
  }

  /// Mark printer as disconnected without attempting actual disconnect
  Future<void> _markDisconnected() async {
    _connectedPrinter = null;
    _availablePrinters = _availablePrinters.map((p) {
      return p.copyWith(isConnected: false);
    }).toList();
    notifyListeners();
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

    // Verify connection before printing
    final isValid = await verifyConnection();
    if (!isValid) {
      debugPrint('PrinterProvider: Connection invalid, cannot test print');
      return false;
    }

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
