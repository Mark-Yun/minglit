import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'seeder_base.dart';
part 'seeder_users.dart';
part 'seeder_parties.dart';
part 'seeder_events.dart';

/// **Database Seeder**
///
/// Handles programmatic data seeding using JSON assets for local development.
class DatabaseSeeder extends _SeederContextBase
    with SeederBase, SeederUsers, SeederEvents, SeederParties {
  DatabaseSeeder(SupabaseClient adminClient) : super(adminClient);

  /// Runs the full seeding process.
  Future<void> seed() async {
    _Log.i('🌱 [Seeder] Starting Fresh Seeding...');

    try {
      // 1. Load Seed Data
      String jsonStr;
      try {
        jsonStr = await rootBundle.loadString(
          'packages/test_data_seeder/assets/seed_data.json',
        );
      } catch (_) {
        _Log.i(
          '⚠️ rootBundle failed, trying direct file access (Test environment)...',
        );
        // Fallback for tests: path depends on where the test is run
        final file = File('../../tests/test_data_seeder/assets/seed_data.json');
        if (!await file.exists()) {
          // Try alternative path (if run from project root)
          final altFile = File('tests/test_data_seeder/assets/seed_data.json');
          jsonStr = await altFile.readAsString();
        } else {
          jsonStr = await file.readAsString();
        }
      }

      final seedData = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 2. Fetch Global Verifications (created by seed.sql)
      final globalVerifIds = await _getGlobalVerificationIds();
      _Log.i('✅ Global Verifications Found: ${globalVerifIds.length} items');

      // 3. Create Normal Users (Personas)
      await _seedPersonas();

      // 4. Create Partners & Diverse Content from JSON
      await _processSeedData(seedData, globalVerifIds);

      _Log.i('✅ [Seeder] Seeding Completed!');
    } on Object catch (e, st) {
      _Log.e('🔥 [Seeder] Seeding Failed', e, st);
      rethrow;
    }
  }
}

abstract class _SeederContext {
  SupabaseClient get adminClient;
}

abstract class _SeederContextBase implements _SeederContext {
  const _SeederContextBase(this.adminClient);

  @override
  final SupabaseClient adminClient;
}
