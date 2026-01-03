class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Pencet Print';
  static const String appVersion = 'v1.0.0';
  static const String appTagline = 'Sekali Pencet, Langsung Print';

  // Paper sizes (in mm)
  static const int paperSize58mm = 58;
  static const int paperSize80mm = 80;

  // Timing
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration scanTimeout = Duration(seconds: 10);

  // Storage keys
  static const String keyLastPrinterMac = 'last_printer_mac';
  static const String keyLastPrinterName = 'last_printer_name';
  static const String keyDefaultPaperSize = 'default_paper_size';
  static const String keyPermissionsGranted = 'permissions_granted';
  static const String keyDarkMode = 'dark_mode';
}
