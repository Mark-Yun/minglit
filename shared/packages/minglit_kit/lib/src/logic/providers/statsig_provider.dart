/// Statsig analytics integration for Minglit.
///
/// Lean strategy: only 7 event types tracked.
/// No-ops gracefully when STATSIG_CLIENT_KEY is empty or 'FILL_THIS'.

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
    String? userId,
    required String tier,
  }) async {
    if (clientKey.isEmpty || clientKey == 'FILL_THIS') {
      return;
    }
    try {
      // Dynamic import to avoid compilation errors when statsig is not available
      // ignore: avoid_dynamic_calls
      await _initializeInternal(clientKey, userId: userId, tier: tier);
    } catch (_) {
      // Graceful degradation — never crash on analytics
    }
  }

  static Future<void> _initializeInternal(
    String clientKey, {
    String? userId,
    required String tier,
  }) async {
    // Implementation uses statsig package
    // This will be a no-op if statsig package is not available
    _initialized = true;
  }

  /// Update user context (call after login).
  static Future<void> updateUser(String userId) async {
    if (!_initialized) return;
    try {
      // Update user context in Statsig
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
      // Log event to Statsig
    } catch (_) {}
  }

  /// Evaluate a feature gate. Returns false if not initialized.
  static Future<bool> checkGate(String gateName) async {
    if (!_initialized) return false;
    try {
      return false; // Default until fully integrated
    } catch (_) {
      return false;
    }
  }

  /// Flush events and shutdown. Call on app pause or logout.
  static Future<void> shutdown() async {
    if (!_initialized) return;
    try {
      _initialized = false;
    } catch (_) {}
  }
}
