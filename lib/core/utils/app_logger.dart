import 'package:flutter/foundation.dart';

/// Debug-only logging for API traffic and auth flow. Every call is gated
/// by kDebugMode, so nothing here ever prints — or leaks a token — in a
/// release build.
class AppLogger {
  AppLogger._();

  static void api(String message) => _print('API', message);
  static void auth(String message) => _print('AUTH', message);
  static void error(String message) => _print('ERROR', message);

  static void _print(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }
}
