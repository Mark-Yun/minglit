import 'package:flutter/foundation.dart';
import 'package:minglit_kit/src/utils/log.dart';

/// Validates that required environment variables are present at runtime.
///
/// Flutter cannot import JSON at build time, so this list is manually
/// synchronised with `env-manifest.json`.  An audit worker detects drift.
///
/// Each key must be declared as a separate `const String.fromEnvironment()`
/// because the argument must be a compile-time constant literal.
class EnvKeyStore {
  EnvKeyStore._();

  // ── manifest.flutter.required ──
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _environment = String.fromEnvironment('ENVIRONMENT');

  // ── manifest.flutter.optional ──
  static const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const _statsigClientKey = String.fromEnvironment('STATSIG_CLIENT_KEY');
  static const _googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _kakaoLocalRestApiKey =
      String.fromEnvironment('KAKAO_LOCAL_REST_API_KEY');
  static const _kakaoMapJavascriptKey =
      String.fromEnvironment('KAKAO_MAP_JAVASCRIPT_KEY');
  static const _jusoConfirmKey = String.fromEnvironment('JUSO_CONFIRM_KEY');
  static const _iamportUserCode = String.fromEnvironment('IAMPORT_USER_CODE');
  static const _mobileRedirectScheme =
      String.fromEnvironment('MOBILE_REDIRECT_SCHEME');

  static const _requiredEntries = <String, String>{
    'SUPABASE_URL': _supabaseUrl,
    'SUPABASE_PUBLISHABLE_KEY': _supabasePublishableKey,
    'ENVIRONMENT': _environment,
  };

  static const _optionalEntries = <String, String>{
    'SENTRY_DSN': _sentryDsn,
    'STATSIG_CLIENT_KEY': _statsigClientKey,
    'GOOGLE_WEB_CLIENT_ID': _googleWebClientId,
    'KAKAO_LOCAL_REST_API_KEY': _kakaoLocalRestApiKey,
    'KAKAO_MAP_JAVASCRIPT_KEY': _kakaoMapJavascriptKey,
    'JUSO_CONFIRM_KEY': _jusoConfirmKey,
    'IAMPORT_USER_CODE': _iamportUserCode,
    'MOBILE_REDIRECT_SCHEME': _mobileRedirectScheme,
  };

  /// Returns names of required env vars that were not injected.
  static List<String> missingRequired() {
    return _requiredEntries.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();
  }

  /// Returns names of optional env vars that were not injected (informational).
  static List<String> missingOptional() {
    return _optionalEntries.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();
  }

  /// Validate environment at app start.
  ///
  /// - **debug**: throws [StateError] so the developer notices immediately.
  /// - **release**: logs via [Log.e] (would go to Sentry in production).
  static void validate() {
    final missing = missingRequired();
    if (missing.isEmpty) {
      final optionalMissing = missingOptional();
      if (optionalMissing.isNotEmpty) {
        Log.w(
          'EnvKeyStore: missing optional env vars: '
          '${optionalMissing.join(', ')}',
        );
      }
      return;
    }

    final message =
        'EnvKeyStore: missing required env vars: ${missing.join(', ')}\n'
        'Run with: flutter run '
        '--dart-define-from-file=../../minglit_env/dev/flutter.env';

    if (kDebugMode) {
      throw StateError(message);
    }
    Log.e(message);
  }
}
