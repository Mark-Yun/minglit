import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_data_seeder/database_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Run Database Seeder', () async {
    // Enable real HTTP requests
    HttpOverrides.global = null;

    // 1. Get Environment Variables
    final url = Platform.environment['SUPABASE_URL'];
    final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

    if (url == null || key == null) {
      print('⚠️ [Seeder] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.');
      print(
        '   Skipping seed execution. (This is expected during build/test unless env vars are set)',
      );
      return;
    }

    print('🚀 [Seeder] Initializing Supabase Client...');
    print('   URL: $url');
    // Don't print the key (security)

    // Initialize Client (AuthFlowType.implicit prevents persistent session issues in CLI)
    final client = SupabaseClient(
      url,
      key,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final seeder = DatabaseSeeder(client);

    await seeder.seed();
  }, timeout: const Timeout(Duration(minutes: 5)));
}
