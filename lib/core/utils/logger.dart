import 'package:flutter/foundation.dart';

/// Minimal logger wrapper. Swap the body for a real logging package later
/// without touching call sites.
class AppLogger {
  AppLogger._();

  static void i(String msg) => _log('INFO', msg);
  static void w(String msg) => _log('WARN', msg);
  static void e(String msg) => _log('ERROR', msg);

  static void _log(String level, String msg) {
    if (kDebugMode) {
      debugPrint('[$level] $msg');
    }
  }
}
