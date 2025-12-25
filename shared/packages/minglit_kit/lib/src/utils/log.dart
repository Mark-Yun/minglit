import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class Log {
  static final Logger _logger = Logger(
    filter: DevelopmentFilter(),
    level: Level.all,
    printer: kIsWeb 
        ? SimplePrinter(printTime: true, colors: false) 
        : PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
            printTime: true,
          ),
  );

  /// Debug 로그
  static void d(String message, [dynamic error]) {
    _logger.d(message, error: error);
  }

  /// Info 로그
  static void i(String message, [dynamic error]) {
    _logger.i(message, error: error);
  }

  /// Warning 로그
  static void w(String message, [dynamic error]) {
    _logger.w(message, error: error);
  }

  /// Error 로그
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
