import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../models/printer_model.dart';

class BluetoothPrinterService {
  BluetoothInfo? _connectedDevice;
  bool _isConnected = false;

  // Optimized chunk settings for bitmap
  static const int _chunkSize = 512;
  static const int _chunkDelayMs = 80;

  bool get isConnected => _isConnected;
  BluetoothInfo? get connectedDevice => _connectedDevice;

  Future<bool> isBluetoothAvailable() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  /// Request Bluetooth permissions for Android 12+
  /// Returns true if all necessary permissions are granted
  Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;

    // Request all Bluetooth permissions for Android 12+
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    // Check if all critical permissions are granted
    bool bluetoothGranted = statuses[Permission.bluetooth]?.isGranted ?? false;
    bool scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    bool connectGranted =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    bool locationGranted =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    debugPrint('Bluetooth permissions status:');
    debugPrint('  bluetooth: $bluetoothGranted');
    debugPrint('  bluetoothScan: $scanGranted');
    debugPrint('  bluetoothConnect: $connectGranted');
    debugPrint('  location: $locationGranted');

    // For Android 12+, we need scan and connect
    // For older Android, we need location
    return (scanGranted && connectGranted) || locationGranted;
  }

  /// Check if all required permissions have been granted without requesting
  Future<bool> checkPermissionsGranted() async {
    if (!Platform.isAndroid) return true;

    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;
    final locationStatus = await Permission.locationWhenInUse.status;

    bool scanGranted = scanStatus.isGranted;
    bool connectGranted = connectStatus.isGranted;
    bool locationGranted = locationStatus.isGranted;

    return (scanGranted && connectGranted) || locationGranted;
  }

  Future<List<PrinterModel>> scanDevices(
      {Duration timeout = const Duration(seconds: 4)}) async {
    List<PrinterModel> printers = [];

    try {
      // Check if permissions are granted (don't request every time)
      final hasPermission = await checkPermissionsGranted();
      if (!hasPermission) {
        debugPrint('Bluetooth permissions not granted');
        return printers;
      }

      // Check if Bluetooth is enabled
      final isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isEnabled) {
        debugPrint('Bluetooth is not enabled');
        return printers;
      }

      // Add delay for chipset compatibility (Snapdragon 685 needs more time)
      await Future.delayed(const Duration(milliseconds: 500));

      final devices = await PrintBluetoothThermal.pairedBluetooths;

      for (var device in devices) {
        printers.add(PrinterModel(
          name: device.name,
          address: device.macAdress,
          isConnected: _connectedDevice?.macAdress == device.macAdress,
        ));
      }

      debugPrint('Found ${printers.length} paired devices');
    } catch (e) {
      debugPrint('Error scanning devices: $e');
    }

    return printers;
  }

  Future<bool> connect(PrinterModel printer) async {
    try {
      print('Connecting to ${printer.name} at ${printer.address}');

      // Disconnect any existing connection first
      try {
        await PrintBluetoothThermal.disconnect;
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {}

      // Try to connect with retry
      bool result = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        print('Connection attempt $attempt...');
        result = await PrintBluetoothThermal.connect(
            macPrinterAddress: printer.address);

        if (result) break;

        await Future.delayed(const Duration(seconds: 1));
      }

      if (result) {
        await Future.delayed(const Duration(seconds: 2));

        _connectedDevice =
            BluetoothInfo(name: printer.name, macAdress: printer.address);
        _isConnected = true;
        print('Connected successfully');
        return true;
      }

      print('Connection failed after 3 attempts');
      return false;
    } catch (e) {
      print('Error connecting: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _connectedDevice = null;
      _isConnected = false;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  Future<bool> _sendChunked(List<int> data) async {
    try {
      print(
          'Sending ${data.length} bytes in ${(data.length / _chunkSize).ceil()} chunks...');

      int offset = 0;

      while (offset < data.length) {
        final end = (offset + _chunkSize > data.length)
            ? data.length
            : offset + _chunkSize;
        final chunk = data.sublist(offset, end);

        final result = await PrintBluetoothThermal.writeBytes(chunk);
        if (!result) {
          print('Failed at offset $offset');
          return false;
        }

        offset += _chunkSize;
        await Future.delayed(Duration(milliseconds: _chunkDelayMs));
      }

      print('All chunks sent successfully');
      return true;
    } catch (e) {
      print('Error sending: $e');
      return false;
    }
  }

  /// Convert image to ESC/POS using generator.image() - most compatible
  Future<List<int>> _imageToEscPos(Uint8List bytes,
      {int paperWidth = 58}) async {
    try {
      final profile = await CapabilityProfile.load();
      final paperSize = paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80;
      final generator = Generator(paperSize, profile);

      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        print('Failed to decode image');
        return [];
      }

      // Target width for printer (384 for 58mm, 576 for 80mm)
      final targetWidth = paperWidth == 58 ? 384 : 576;

      // Just resize - let esc_pos_utils handle dithering
      final resized = img.copyResize(image, width: targetWidth);

      print('Image prepared: ${resized.width}x${resized.height}');

      // Build commands
      List<int> commands = [];
      commands.addAll(generator.reset());

      // IMPORTANT: Use generator.image() NOT imageRaster()
      // generator.image() uses ESC * mode which is most compatible
      commands.addAll(generator.image(resized, align: PosAlign.center));

      // Feed only, NO cut (many cheap printers don't have cutter)
      commands.addAll(generator.feed(3));

      print('Generated ${commands.length} bytes');
      return commands;
    } catch (e) {
      print('Error converting image: $e');
      return [];
    }
  }

  Future<bool> printImage(Uint8List imageBytes, {int paperWidth = 58}) async {
    if (!_isConnected) {
      print('Not connected');
      return false;
    }

    try {
      print('Preparing image for print...');
      final escCommands =
          await _imageToEscPos(imageBytes, paperWidth: paperWidth);

      if (escCommands.isEmpty) {
        print('No commands generated');
        return false;
      }

      // Send ALL at once - no chunking
      print('Sending ${escCommands.length} bytes directly...');
      final success = await PrintBluetoothThermal.writeBytes(escCommands);

      if (success) {
        print('Image printed successfully!');
      } else {
        print('Failed to send');
      }
      return success;
    } catch (e) {
      print('Error printing image: $e');
      return false;
    }
  }

  Future<bool> printTestPage() async {
    if (!_isConnected) {
      print('Not connected');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      List<int> commands = [];

      commands.addAll(generator.reset());

      commands.addAll(generator.text(
        '================================',
        styles: const PosStyles(align: PosAlign.center),
      ));

      commands.addAll(generator.text(
        'PENCET PRINT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ));

      commands.addAll(generator.emptyLines(1));

      commands.addAll(generator.text(
        'Test Print Berhasil!',
        styles: const PosStyles(align: PosAlign.center),
      ));

      commands.addAll(generator.text(
        'Printer Terhubung',
        styles: const PosStyles(align: PosAlign.center),
      ));

      commands.addAll(generator.emptyLines(1));

      commands.addAll(generator.text(
        '================================',
        styles: const PosStyles(align: PosAlign.center),
      ));

      commands.addAll(generator.text(
        'Terima kasih sudah',
        styles: const PosStyles(align: PosAlign.center),
      ));

      commands.addAll(generator.text(
        'menggunakan Pencet Print',
        styles: const PosStyles(align: PosAlign.center),
      ));

      // Feed only, no cut
      commands.addAll(generator.feed(4));

      print('Sending test page...');
      final result = await PrintBluetoothThermal.writeBytes(commands);

      print(result ? 'Test page sent!' : 'Failed to send');
      return result;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  void initializeListeners() {}
  void dispose() {}
}
