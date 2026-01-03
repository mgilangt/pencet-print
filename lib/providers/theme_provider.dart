import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Initialize theme from saved preferences
  Future<void> init() async {
    _isDarkMode = await _settingsService.getDarkMode();
    notifyListeners();
  }

  /// Toggle between dark and light mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settingsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  /// Set specific theme mode
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _settingsService.setDarkMode(isDark);
    notifyListeners();
  }
}
