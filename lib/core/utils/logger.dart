import 'package:flutter/foundation.dart';

/// Development logger for the application.
/// In production, this can be replaced with a proper logging framework.
class AppLogger {
  AppLogger._();

  static const String _tag = 'SnookerClub';

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('\x1B[36m[$_tag] DEBUG: $message\x1B[0m');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('\x1B[32m[$_tag] INFO: $message\x1B[0m');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('\x1B[33m[$_tag] WARNING: $message\x1B[0m');
    }
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('\x1B[31m[$_tag] ERROR: $message\x1B[0m');
      if (error != null) {
        debugPrint('\x1B[31m[$_tag] Error details: $error\x1B[0m');
      }
      if (stackTrace != null) {
        debugPrint('\x1B[31m[$_tag] Stack trace: $stackTrace\x1B[0m');
      }
    }
  }
}
