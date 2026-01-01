import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

class SettingsService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Last connected printer
  Future<void> saveLastPrinter(String name, String mac) async {
    await init();
    await _prefs!.setString(AppConstants.keyLastPrinterName, name);
    await _prefs!.setString(AppConstants.keyLastPrinterMac, mac);
  }

  Future<String?> getLastPrinterName() async {
    await init();
    return _prefs!.getString(AppConstants.keyLastPrinterName);
  }

  Future<String?> getLastPrinterMac() async {
    await init();
    return _prefs!.getString(AppConstants.keyLastPrinterMac);
  }

  // Default paper size
  Future<void> saveDefaultPaperSize(int size) async {
    await init();
    await _prefs!.setInt(AppConstants.keyDefaultPaperSize, size);
  }

  Future<int> getDefaultPaperSize() async {
    await init();
    return _prefs!.getInt(AppConstants.keyDefaultPaperSize) ??
        AppConstants.paperSize80mm;
  }

  // Clear all settings
  Future<void> clearAll() async {
    await init();
    await _prefs!.clear();
  }
}
