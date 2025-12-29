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

    // E. Create Party System Data
    await _seedPartySet(partnerId, index);
  }

  Future<void> _seedPartySet(String partnerId, int index) async {
    // 1. Location
    final locRes = await _adminClient
        .from('locations')
        .insert({
          'partner_id': partnerId,
          'name': 'Gangnam Branch #$index',
          'address': 'Seoul Gangnam-gu Teheran-ro ${100 + index}',
          'sido': 'Seoul',
          'sigungu': 'Gangnam-gu',
          // geo_point skipped for now (needs RPC or PostGIS driver)
        })
        .select('id')
        .single();
    final locationId = locRes['id'] as String;

    // 2. Party (Theme)
    final partyRes = await _adminClient
        .from('parties')
        .insert({
          'partner_id': partnerId,
          'title': 'Friday Night Fever #$index',
          'description': {'text': 'Come and join the best party in town!'},
          'status': 'active',
          'contact_phone': '02-1234-${1000 + index}',
        })
        .select('id')
        .single();
    final partyId = partyRes['id'] as String;

    // 3. Event (Instance)
    // Date: 3 days later, 19:00
    final startTime = DateTime.now()
        .add(const Duration(days: 3))
        .toIso8601String();
    final endTime = DateTime.now()
        .add(const Duration(days: 3, hours: 4))
        .toIso8601String();

    final eventRes = await _adminClient
        .from('events')
        .insert({
          'party_id': partyId,
          'location_id': locationId,
          'title': 'Vol.1 Grand Opening',
          'start_time': startTime,
          'end_time': endTime,
          'max_participants': 40,
          'status': 'scheduled',
        })
        .select('id')
        .single();
    final eventId = eventRes['id'] as String;

    // 4. Tickets
    await _adminClient.from('event_tickets').insert([
      {
        'event_id': eventId,
        'name': 'Male Early Bird',
        'price': 30000,
        'quantity': 20,
        'gender': 'male',
        'status': 'on_sale',
      },
      {
        'event_id': eventId,
        'name': 'Female Early Bird',
        'price': 10000,
        'quantity': 20,
        'gender': 'female',
        'status': 'on_sale',
      },
    ]);
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
