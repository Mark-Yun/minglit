import 'package:logger/logger.dart';

/// Static utility class for logging throughout the app.
class Log {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      lineLength: 80,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Debug level log.
  static void d(String message) => _logger.d(message);

  /// Info level log.
  static void i(String message) => _logger.i(message);

  /// Warning level log.
  static void w(String message) => _logger.w(message);

  /// Error level log.
  static void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
