import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_data_seeder/database_seeder.dart';

/// **TestHelper**
///
/// Provides centralized initialization logic for integration tests.
class TestHelper {
  /// Initializes the Flutter binding, Supabase, and returns a Riverpod container.
  static Future<ProviderContainer> initialize() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set.\n'
        'Run with: --dart-define-from-file=../../minglit_env/local/flutter.env',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    // Create a provider container for logic-only testing
    final container = ProviderContainer();
    return container;
  }
}

/// **SeederHelper**
///
/// A wrapper around [DatabaseSeeder] to prepare test data within integration tests.
class SeederHelper {
  SeederHelper()
    : _seeder = DatabaseSeeder(
        SupabaseClient(
          const String.fromEnvironment('SUPABASE_URL'),
          const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY'),
        ),
      );

  final DatabaseSeeder _seeder;

  /// Resets the database and seeds basic data for scenarios.
  Future<void> prepareBaseData() async {
    Log.i('🧪 [SeederHelper] Preparing base data...');
    await _seeder.seed();
    Log.i('🧪 [SeederHelper] Base data ready.');
  }

  /// Creates a specific pair of users for matching tests.
  Future<(String, String)> createPairForMatching() async {
    // TODO: Implement specific seeding logic if needed
    // For now, assume users exist or use seeder methods
    return ('user-a-id', 'user-b-id');
  }
}
