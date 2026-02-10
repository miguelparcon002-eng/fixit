import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Lightweight app logger to avoid using `print()` in production code.
///
/// Use [p] as a drop-in replacement for `print(...)`.
class AppLogger {
  AppLogger._();

  /// Print-like logging helper.
  ///
  /// Accepts any object (including null) and logs its string form.
  static void p(
    Object? message, {
    String name = 'FixIt',
    Object? error,
    StackTrace? stackTrace,
  }) {
    d(message?.toString() ?? 'null', name: name, error: error, stackTrace: stackTrace);
  }

  static void d(
    String message, {
    String name = 'FixIt',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace);

    if (!kReleaseMode) {
      debugPrint('[$name] $message');
      if (error != null) debugPrint('[$name] error: $error');
      if (stackTrace != null) debugPrint('[$name] stack: $stackTrace');
    }
  }

  static void e(
    String message, {
    String name = 'FixIt',
    Object? error,
    StackTrace? stackTrace,
  }) {
    d(message, name: name, error: error, stackTrace: stackTrace);
  }
}
