/// Environment configuration for E2E tests.
///
/// All values are injected via `--dart-define` at test invocation time.
/// CI uses GH Secrets; local runs use values from `minglit_env/dev/`.
class E2eConfig {
  E2eConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const serviceRoleKey =
      String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

  /// All seed test users share this password.
  static const testPassword = 'password1234!';

  /// Validates that all required env vars are present.
  /// Throws [StateError] if any is missing — fails fast in CI.
  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabasePublishableKey.isEmpty) {
      missing.add('SUPABASE_PUBLISHABLE_KEY');
    }
    if (serviceRoleKey.isEmpty) missing.add('SUPABASE_SERVICE_ROLE_KEY');

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required --dart-define values: ${missing.join(', ')}\n'
        'Run with: flutter test integration_test/ '
        '--dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=... '
        '--dart-define=SUPABASE_SERVICE_ROLE_KEY=...',
      );
    }
  }
}
