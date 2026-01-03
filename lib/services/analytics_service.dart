import 'package:firebase_analytics/firebase_analytics.dart';

/// Analytics service for tracking app events
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get analytics instance for NavigatorObserver
  static FirebaseAnalytics get instance => _analytics;
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Track when a printer is connected
  static Future<void> logPrinterConnected(String printerName) async {
    await _analytics.logEvent(
      name: 'printer_connected',
      parameters: {
        'printer_name': printerName,
      },
    );
  }

  /// Track when print is successful
  static Future<void> logPrintSuccess({
    required String printerName,
    required String paperSize,
    required int copies,
    required String fileType,
  }) async {
    await _analytics.logEvent(
      name: 'print_success',
      parameters: {
        'printer_name': printerName,
        'paper_size': paperSize,
        'copies': copies,
        'file_type': fileType,
      },
    );
  }

  /// Track when print fails
  static Future<void> logPrintFailed({
    String? printerName,
    String? reason,
  }) async {
    await _analytics.logEvent(
      name: 'print_failed',
      parameters: {
        'printer_name': printerName ?? 'unknown',
        'reason': reason ?? 'unknown',
      },
    );
  }

  /// Track when user changes paper size setting
  static Future<void> logPaperSizeChanged(int paperSize) async {
    await _analytics.logEvent(
      name: 'paper_size_changed',
      parameters: {
        'paper_size': '${paperSize}mm',
      },
    );
  }

  /// Track when user uses share intent
  static Future<void> logShareIntentUsed(String fileType) async {
    await _analytics.logEvent(
      name: 'share_intent_used',
      parameters: {
        'file_type': fileType,
      },
    );
  }

  /// Track when dark mode is toggled
  static Future<void> logThemeChanged(bool isDarkMode) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {
        'is_dark_mode': isDarkMode,
      },
    );
  }

  /// Track screen view
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}
