/// Statsig analytics integration for Minglit.
///
/// Lean strategy: only 7 event types tracked.
/// No-ops gracefully when STATSIG_CLIENT_KEY is empty or 'FILL_THIS'.
library;

import 'package:statsig/statsig.dart';

/// Event name constants for Statsig analytics.
/// ONLY these 7 events are tracked.
class MingLitEvent {
  MingLitEvent._();

  static const String appOpened = 'app_opened';
  static const String eventViewed = 'event_viewed';
  static const String eventApplied = 'event_applied';
  static const String paymentCompleted = 'payment_completed';
  static const String paymentFailed = 'payment_failed';
  static const String matchingResult = 'matching_result';
  static const String errorOccurred = 'error_occurred';
}

/// Statsig analytics singleton.
/// Follows the same conditional-init pattern as Sentry.
/// No-ops gracefully when STATSIG_CLIENT_KEY is empty.
class StatsigAnalytics {
  StatsigAnalytics._();

  static bool _initialized = false;

  /// Initialize Statsig. No-ops if [clientKey] is empty or 'FILL_THIS'.
  static Future<void> initialize(
    String clientKey, {
    required String tier,
    String? userId,
  }) async {
    if (clientKey.isEmpty || clientKey == 'FILL_THIS') {
      return;
    }
    try {
      await _initializeInternal(clientKey, userId: userId, tier: tier);
    } catch (_) {
      // Graceful degradation — never crash on analytics
    }
  }

  static Future<void> _initializeInternal(
    String clientKey, {
    required String tier,
    String? userId,
  }) async {
    final user = StatsigUser(userId: userId ?? '');
    final options = StatsigOptions(environment: tier);
    await Statsig.initialize(clientKey, user, options);
    _initialized = true;
  }

  /// Update user context (call after login).
  static Future<void> updateUser(String userId) async {
    if (!_initialized) return;
    try {
      await Statsig.updateUser(StatsigUser(userId: userId));
    } catch (_) {}
  }

  /// Log an analytics event. Use [MingLitEvent] constants.
  static void logEvent(
    String eventName, {
    double? value,
    Map<String, String>? metadata,
  }) {
    if (!_initialized) return;
    try {
      Statsig.logEvent(eventName, doubleValue: value, metadata: metadata);
    } catch (_) {}
  }

  /// Evaluate a feature gate. Returns false if not initialized.
  static bool checkGate(String gateName) {
    if (!_initialized) return false;
    try {
      return Statsig.checkGate(gateName);
    } catch (_) {
      return false;
    }
  }

  /// Flush events and shutdown. Call on app pause or logout.
  static Future<void> shutdown() async {
    if (!_initialized) return;
    try {
      await Statsig.shutdown();
      _initialized = false;
    } catch (_) {}
  }
}
