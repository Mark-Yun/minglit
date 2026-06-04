/// Configuration for Dev features.
class DevConfig {
  /// Legacy initializer kept only to avoid breaking stale dev imports.
  ///
  /// Flutter clients must not construct elevated Supabase clients. Dev/admin
  /// operations should go through dev-only Edge Functions instead.
  @Deprecated(
    'Client admin Supabase access was removed. Use dev Edge Functions.',
  )
  static void init(String url, String elevatedCredential) {
    throw UnsupportedError(
      'Client admin Supabase access was removed. Use dev Edge Functions.',
    );
  }

  /// Removed legacy admin client accessor.
  static Never get adminClient {
    throw StateError(
      'Client admin Supabase access was removed. Use dev Edge Functions.',
    );
  }

  /// Client admin access is no longer initialized in Flutter code.
  static bool get isInitialized => false;
}
