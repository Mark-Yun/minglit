import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Static utility class for logging throughout the app.
class Log {
  static final Logger _logger = Logger(
    // Use SimplePrinter to save memory and keep logs clean
    printer: SimplePrinter(printTime: true, colors: false),
    filter: _AllowAllFilter(),
    output: _MemoryLogOutput(),
  );

  /// Internal memory log storage
  static final ListQueue<String> _logHistory = ListQueue<String>();
  static const int _maxHistorySize = 1000;

  /// Debug level log.
  static void d(String message) => _logger.d(message);

  /// Info level log.
  static void i(String message) => _logger.i(message);

  /// Warning level log.
  static void w(String message) => _logger.w(message);

  /// Error level log.
  static void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Export collected logs as a single string.
  static String export() {
    return _logHistory.join('\n');
  }

  /// Clear log history.
  static void clear() {
    _logHistory.clear();
  }

  /// Internal method to add log to history
  static void _addToHistory(String line) {
    if (_logHistory.length >= _maxHistorySize) {
      _logHistory.removeFirst();
    }
    _logHistory.add(line);
  }
}

/// Filter that allows all logs to pass to Output phase
class _AllowAllFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

/// Custom LogOutput that writes to console AND memory
class _MemoryLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // 1. Write to memory (History) - ALWAYS
    // With SimplePrinter, event.lines usually contains one formatted line per log
    for (var line in event.lines) {
      Log._addToHistory(line);
    }

    // 2. Write to console - ONLY if NOT Release Mode
    if (!kReleaseMode) {
      for (var line in event.lines) {
        debugPrint(line);
      }
    }
  }
}
