import 'dart:math';

import 'package:minglit_kit/src/utils/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// **Database Seeder**
///
/// Handles programmatic data seeding for local development.
/// Requires a [SupabaseClient] initialized with
/// **SERVICE ROLE KEY**.
class DatabaseSeeder {
  DatabaseSeeder(this._adminClient);

  final SupabaseClient _adminClient;
  final _random = Random();

  /// Runs the full seeding process.
  Future<void> seed() async {
    Log.i('🌱 [Seeder] Starting Database Seeding...');

    try {
      // 1. Clean up (Optional: You might rely on 'db reset' instead)
      // We cannot easily truncate via API, so we assume DB is clean or handles
      // conflicts. For a true reset, use 'supabase db reset' in terminal.

      // 2. Create Partners & Owners & Staffs
      for (var i = 1; i <= 10; i++) {
        await _seedPartnerSet(i);
      }

      // 3. Create Normal Users
      await _seedNormalUsers();

      Log.i('🌳 [Seeder] Seeding Completed Successfully!');
    } catch (e, st) {
      Log.e('🔥 [Seeder] Seeding Failed', e, st);
      rethrow;
    }
  }

  Future<void> _seedPartnerSet(int index) async {
    final partnerName = 'Partner Shop $index';
    Log.d('Creating $partnerName...');

    // A. Create Owner
    final ownerEmail = 'owner$index@test.com';
    final ownerId = await _createUser(
      email: ownerEmail,
      password: 'password',
      meta: {
        'name': 'Owner $index',
        'username': 'owner_$index',
        'is_verified': true,
        'gender': 'male',
      },
    );

    // B. Create Partner
    final partnerRes = await _adminClient
        .from('partners')
        .insert({
          'name': partnerName,
          'introduction': 'Best shop in town #$index',
          'contact_email': ownerEmail,
          'biz_name': 'Minglit Biz $index',
          'biz_number': '123-00-${10000 + index}',
          'is_active': true,
        })
        .select('id')
        .single();
    final partnerId = partnerRes['id'] as String;

    // C. Link Owner
    await _adminClient.from('partner_member_permissions').insert({
      'partner_id': partnerId,
      'user_id': ownerId,
      'role': 'owner',
    });

    // D. Create Staffs (1~3 per partner)
    final staffCount = 1 + _random.nextInt(3); // 1 to 3
    for (var j = 1; j <= staffCount; j++) {
      final staffEmail = 'staff$index-$j@test.com'; // staff1-1@test.com
      final staffId = await _createUser(
        email: staffEmail,
        password: 'password',
        meta: {
          'name': 'Staff $index-$j',
          'username': 'staff_${index}_$j',
          'is_verified': true,
          'gender': 'female',
        },
      );

      await _adminClient.from('partner_member_permissions').insert({
        'partner_id': partnerId,
        'user_id': staffId,
        'role': 'staff',
        'permissions': ['VERIFY_LIST_VIEW', 'COMMENT_MANAGE'],
      });
    }
  }

  Future<void> _seedNormalUsers() async {
    Log.d('Creating 20 Normal Users...'); // Reduced from 100 for speed in UI
    for (var i = 1; i <= 20; i++) {
      final gender = i.isOdd ? 'male' : 'female';
      await _createUser(
        email: 'user$i@test.com',
        password: 'password',
        meta: {
          'name': 'User $i',
          'username': 'user_$i',
          'is_verified': i % 3 == 0,
          'gender': gender,
        },
      );
    }
  }

  /// Creates a user using Admin API. Returns User ID.
  Future<String> _createUser({
    required String email,
    required String password,
    required Map<String, dynamic> meta,
  }) async {
    // Check if exists (Clean DB is better, but handle idempotency)
    try {
      final res = await _adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: meta,
        ),
      );
      return res.user!.id;
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        Log.w('User $email already exists. Skipping creation.');
        rethrow;
      }
      rethrow;
    }
  }
}
