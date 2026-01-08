import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// **Database Seeder**
///
/// Handles programmatic data seeding using JSON assets for local development.
class DatabaseSeeder {
  DatabaseSeeder(this._adminClient);

  final SupabaseClient _adminClient;

  /// Runs the full seeding process.
  Future<void> seed() async {
    Log.i('🌱 [Seeder] Starting Fresh Seeding from JSON...');

    try {
      // 1. Load Seed Data from JSON
      final jsonStr = await rootBundle.loadString(
        'packages/minglit_kit/assets/seed/seed_data.json',
      );
      final seedData = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 2. Fetch Global Verifications (created by seed.sql)
      final globalVerifIds = await _getGlobalVerificationIds();
      Log.i('✅ Global Verifications Found: ${globalVerifIds.length} items');

      // 3. Create Normal Users
      await _seedUsers();

      // 4. Create Partners & Diverse Content from JSON
      await _processSeedData(seedData, globalVerifIds);

      Log.i('✅ [Seeder] Seeding Completed!');
    } on Object catch (e, st) {
      Log.e('🔥 [Seeder] Seeding Failed', e, st);
      rethrow;
    }
  }

  Future<List<String>> _getGlobalVerificationIds() async {
    final result = await _adminClient
        .from('verifications')
        .select('id')
        .filter('partner_id', 'is', null);

    return (result as List)
        .map((dynamic e) => (e as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  Future<void> _seedUsers() async {
    Log.i('👥 Step 1: Seeding 100 Normal Users...');
    for (var i = 1; i <= 100; i++) {
      final metadata = <String, dynamic>{
        'name': 'User $i',
        'username': 'user_$i',
        'gender': i.isOdd ? 'male' : 'female',
        'phone_number': '010-${1000 + i}-${2000 + i}',
      };

      await _createAdminUser(
        email: 'user$i@test.com',
        password: 'password',
        metadata: metadata,
      );
    }
  }

  Future<void> _processSeedData(
    Map<String, dynamic> seedData,
    List<String> globalVerifIds,
  ) async {
    final partners = seedData['partners'] as List<dynamic>;
    final genericCount = seedData['generic_partners_count'] as int? ?? 0;

    Log.i('🏢 Step 2: Processing ${partners.length} defined partners...');

    // 1. Process Defined Partners (e.g. Partner 1, 2)
    for (final dynamic p in partners) {
      final pData = p as Map<String, dynamic>;
      final index = pData['index'] as int;
      final partnerName = pData['name'] as String;
      final email = pData['email'] as String;

      // Create Owner
      final ownerId = await _createAdminUser(
        email: email,
        password: 'password',
        metadata: {
          'name': 'Owner $index ($partnerName)',
          'username': 'owner_$index',
          'gender': 'male',
        },
      );

      // Create Partner
      final partnerRes = await _adminClient
          .from('partners')
          .insert({
            'name': partnerName,
            'introduction': pData['introduction'] ?? 'Premium Store',
            'biz_name': pData['biz_name'],
            'biz_number': pData['biz_number'],
            'contact_email': email,
          })
          .select('id')
          .single();
      final partnerId = partnerRes['id'] as String;

      // Link Owner
      await _adminClient.from('partner_member_permissions').insert({
        'partner_id': partnerId,
        'user_id': ownerId,
        'role': 'owner',
      });

      // Create Location
      final locationRes = await _adminClient
          .from('locations')
          .insert({
            'partner_id': partnerId,
            'name': '$partnerName Main Branch',
            'address': 'Seoul Gangnam-gu Gangnam-daero ${396 + index}',
            'geo_point': 'POINT(127.0276 37.4979)',
          })
          .select('id')
          .single();
      final locationId = locationRes['id'] as String;

      // Create Local Verifications
      final localVerifIds = <String>[];
      final verifs = pData['verifications'] as List<dynamic>? ?? [];
      if (verifs.isNotEmpty) {
        final localVerifRes = await _adminClient
            .from('verifications')
            .insert(
              verifs.map((dynamic v) {
                final vMap = v as Map<String, dynamic>;
                return {...vMap, 'partner_id': partnerId};
              }).toList(),
            )
            .select('id');
        localVerifIds.addAll(
          (localVerifRes as List).map(
            (dynamic e) => (e as Map<String, dynamic>)['id'] as String,
          ),
        );
      }

      // Create Parties
      final parties = pData['parties'] as List<dynamic>? ?? [];
      for (final dynamic pEntry in parties) {
        final partyData = pEntry as Map<String, dynamic>;
        final partyId = const Uuid().v4();

        // Map Entry Groups
        final entryGroups = (partyData['entry_groups'] as List<dynamic>).map((
          dynamic g,
        ) {
          final gMap = g as Map<String, dynamic>;
          final groupUuid = const Uuid().v4();
          final requiredIds = <String>[];

          // Add Global Verifs
          final globalIndices = gMap['use_global_ids'] as List<dynamic>? ?? [];
          for (final dynamic gi in globalIndices) {
            final idx = gi as int;
            if (globalVerifIds.length > idx) {
              requiredIds.add(globalVerifIds[idx]);
            }
          }

          // Add Local Verifs
          final localIndices =
              gMap['use_local_indices'] as List<dynamic>? ?? [];
          for (final dynamic li in localIndices) {
            final idx = li as int;
            if (localVerifIds.length > idx) {
              requiredIds.add(localVerifIds[idx]);
            }
          }

          return {
            'id': groupUuid,
            'label': gMap['label'],
            'gender': gMap['gender'],
            'birth_year_range': gMap['birth_year_range'],
            'required_verification_ids': requiredIds,
          };
        }).toList();

        final allVerifIds = entryGroups
            .expand((e) => e['required_verification_ids'] as List)
            .toSet()
            .toList();

        await _adminClient.from('parties').insert({
          'id': partyId,
          'partner_id': partnerId,
          'location_id': locationId,
          'title': partyData['title'],
          'description': {
            'ops': [
              {'insert': '${partyData['description']}\n'},
            ],
          },
          'min_confirmed_count': 5,
          'max_participants': 20,
          'conditions': entryGroups,
          'required_verification_ids': allVerifIds,
        });

        // Create Tickets
        final tickets = partyData['tickets'] as List<dynamic>? ?? [];
        await _adminClient
            .from('tickets')
            .insert(
              tickets.map((dynamic t) {
                final tMap = t as Map<String, dynamic>;
                final groupIdx = tMap['group_index'] as int;
                return {
                  'party_id': partyId,
                  'name': tMap['name'],
                  'price': tMap['price'],
                  'quantity': tMap['quantity'],
                  'target_entry_group_ids': [entryGroups[groupIdx]['id']],
                };
              }).toList(),
            );
      }
    }

    // 2. Create Generic Partners if needed
    if (genericCount > 0) {
      Log.i('🏢 Step 3: Seeding $genericCount generic partners...');
    }
  }

  Future<String> _createAdminUser({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final res = await _adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: metadata,
        ),
      );
      final user = res.user;
      if (user == null) {
        throw const MinglitSystemException('User creation failed');
      }
      return user.id;
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.code == 'email_exists') {
        final usersRes = await _adminClient.auth.admin.listUsers(perPage: 1000);
        try {
          final existing = usersRes.firstWhere((u) => u.email == email);
          await _adminClient.auth.admin.deleteUser(existing.id);
        } on Object catch (_) {}
        return _createAdminUser(
          email: email,
          password: password,
          metadata: metadata,
        );
      }
      rethrow;
    }
  }
}
