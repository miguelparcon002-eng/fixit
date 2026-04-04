import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
class AppLogger {
  AppLogger._();
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