import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/dev/database_seeder.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Dev Database Seeding Runner', (WidgetTester tester) async {
    // 1. Environment Variables Validation
    final url = Platform.environment['SUPABASE_DEV_URL'];
    final secretKey = Platform.environment['SUPABASE_DEV_SECRET_KEY'];

    if (url == null || url.isEmpty) {
      Log.e('❌ [Error] Missing SUPABASE_DEV_URL environment variable.');
      fail('Missing SUPABASE_DEV_URL');
    }
    if (secretKey == null || secretKey.isEmpty) {
      Log.e('❌ [Error] Missing SUPABASE_DEV_SECRET_KEY environment variable.');
      fail('Missing SUPABASE_DEV_SECRET_KEY');
    }

    Log.i('🚀 [Seeder Runner] Starting Seeding Process...');
    Log.d('📍 Target URL: $url');

    // 2. Initialize Supabase Admin Client
    final supabase = SupabaseClient(url, secretKey);

    // 3. Run Seeder
    final seeder = DatabaseSeeder(supabase);

    try {
      await seeder.seed();
      Log.i('✅ [Seeder Runner] Successfully Completed!');
    } catch (e, st) {
      Log.e('🔥 [Seeder Runner] Failed with error', e, st);
      fail('Seeding execution failed: $e');
    }
  });
}
