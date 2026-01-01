import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  int _paperSize = AppConstants.paperSize80mm;

  int get paperSize => _paperSize;
  bool get isSmallPaper => _paperSize == AppConstants.paperSize58mm;
  bool get isLargePaper => _paperSize == AppConstants.paperSize80mm;

  /// Initialize settings
  Future<void> init() async {
    _paperSize = await _settingsService.getDefaultPaperSize();
    notifyListeners();
  }

  /// Set paper size
  Future<void> setPaperSize(int size) async {
    _paperSize = size;
    await _settingsService.saveDefaultPaperSize(size);
    notifyListeners();
  }
}
