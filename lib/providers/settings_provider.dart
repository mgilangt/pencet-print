import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  int _paperSize = AppConstants.paperSize80mm;
  bool _isInitialized = false;

  int get paperSize => _paperSize;
  bool get isSmallPaper => _paperSize == AppConstants.paperSize58mm;
  bool get isLargePaper => _paperSize == AppConstants.paperSize80mm;
  bool get isInitialized => _isInitialized;

  /// Initialize settings - loads saved paper size from storage
  /// This should be called early in app lifecycle
  Future<void> init() async {
    if (_isInitialized) return; // Prevent double init

    _paperSize = await _settingsService.getDefaultPaperSize();
    _isInitialized = true;
    notifyListeners();
  }

  /// Force reload settings from storage
  /// Use this when app resumes from background
  Future<void> reload() async {
    _paperSize = await _settingsService.getDefaultPaperSize();
    notifyListeners();
  }

  /// Set paper size and save to storage
  Future<void> setPaperSize(int size) async {
    _paperSize = size;
    await _settingsService.saveDefaultPaperSize(size);
    notifyListeners();
  }
}
