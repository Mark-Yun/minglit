import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration for Dev features.
class DevConfig {
  static SupabaseClient? _adminClient;

  /// Initialize with Service Role Key (ONLY IN DEV MAIN).
  static void init(String url, String serviceRoleKey) {
    _adminClient = SupabaseClient(url, serviceRoleKey);
  }

  /// Get the admin client. Throws if not initialized.
  static SupabaseClient get adminClient {
    if (_adminClient == null) {
      throw StateError(
        'DevConfig not initialized. Call init() with Service Role Key.',
      );
    }
    return _adminClient!;
  }

  /// Whether the admin client has been initialized.
  static bool get isInitialized => _adminClient != null;
}
