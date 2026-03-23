/// Statsig analytics integration for Minglit.
///
/// Lean strategy: only 7 event types tracked.
/// No-ops gracefully when STATSIG_CLIENT_KEY is empty or 'FILL_THIS'.
library;

import 'package:minglit_kit/src/utils/log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statsig/statsig.dart';
import 'package:uuid/uuid.dart';

/// Event name constants for Statsig analytics.
/// ONLY these 7 events are tracked.
class MingLitEvent {
  MingLitEvent._();

  /// Event fired when the app is opened.
  static const String appOpened = 'app_opened';

  /// Event fired when an event detail is viewed.
  static const String eventViewed = 'event_viewed';

  /// Event fired when a user applies to an event.
  static const String eventApplied = 'event_applied';

  /// Event fired when a payment is completed successfully.
  static const String paymentCompleted = 'payment_completed';

  /// Event fired when a payment fails.
  static const String paymentFailed = 'payment_failed';

  /// Event fired with a matching result.
  static const String matchingResult = 'matching_result';

  /// Event fired when an unexpected error occurs.
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
    } on Object catch (e) {
      // Fix #382: Graceful degradation — never crash on analytics, but log for debuggability
      Log.d('Statsig initialize failed: $e');
    }
  }

  static const _stableIdKey = 'statsig_stable_id';

  static Future<void> _initializeInternal(
    String clientKey, {
    required String tier,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var stableId = prefs.getString(_stableIdKey);
    if (stableId == null) {
      stableId = const Uuid().v4();
      await prefs.setString(_stableIdKey, stableId);
    }

    final user = StatsigUser(
      userId: userId ?? '',
      customIds: {'stableID': stableId},
    );
    final options = StatsigOptions(environment: tier);
    await Statsig.initialize(clientKey, user, options);
    _initialized = true;
  }

  /// Update user context (call after login).
  static Future<void> updateUser(String userId) async {
    if (!_initialized) return;
    try {
      await Statsig.updateUser(StatsigUser(userId: userId));
      // Fix #382: 에러 삼킴 방지 — debug 로그 추가
    } on Object catch (e) {
      Log.d('Statsig updateUser failed: $e');
    }
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
      // Fix #382: 에러 삼킴 방지 — debug 로그 추가
    } on Object catch (e) {
      Log.d('Statsig logEvent failed: $e');
    }
  }

  /// Evaluate a feature gate. Returns false if not initialized.
  static bool checkGate(String gateName) {
    if (!_initialized) return false;
    try {
      return Statsig.checkGate(gateName);
    } on Object catch (_) {
      return false;
    }
  }

  /// Flush events and shutdown. Call on app pause or logout.
  static Future<void> shutdown() async {
    if (!_initialized) return;
    try {
      await Statsig.shutdown();
      _initialized = false;
      // Fix #382: 에러 삼킴 방지 — debug 로그 추가
    } on Object catch (e) {
      Log.d('Statsig shutdown failed: $e');
    }
  }
}
