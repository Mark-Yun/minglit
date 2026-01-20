import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../utils/test_config.dart';
import '../utils/test_helpers.dart';

void main() {
  final adminClient = SupabaseClient(
    TestConfig.supabaseUrl,
    TestConfig.serviceRoleKey,
    headers: {
      'Authorization': 'Bearer ${TestConfig.serviceRoleKey}',
      'apikey': TestConfig.serviceRoleKey,
    },
  );

  SupabaseClient createUserClient(String userId) {
    final jwt = JWT({
      'sub': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'user_$userId@example.com',
    });
    final token = jwt.sign(SecretKey(TestConfig.jwtSecret));

    return SupabaseClient(
      TestConfig.supabaseUrl,
      TestConfig.serviceRoleKey,
      headers: {
        'Authorization': 'Bearer $token',
        'apikey': TestConfig.serviceRoleKey,
      },
    );
  }

  group('Party RLS Tests', () {
    late String ownerId;
    late String guestId;
    late String partnerId;
    late String partyId;

    setUpAll(() async {
      print('🚀 [Setup] Fetching data for Party RLS...');

      // Get Test User as Guest via Helper
      guestId = await getMale25VerifiedUserId(adminClient);

      // Get Owner (from Partner)
      final p1 = await adminClient
          .from('partners')
          .select('id, partner_member_permissions(user_id)')
          .limit(1)
          .single();
      partnerId = p1['id'];
      ownerId = (p1['partner_member_permissions'] as List).first['user_id'];

      // Get a Party owned by this partner
      final party = await adminClient
          .from('parties')
          .select()
          .eq('partner_id', partnerId)
          .limit(1)
          .single();
      partyId = party['id'];

      print('✅ [Setup] Owner: $ownerId, Guest: $guestId, Party: $partyId');
    });

    test('Owner should be able to update party', () async {
      final client = createUserClient(ownerId);
      final newTitle = 'Updated by Owner ${DateTime.now().millisecond}';

      await client
          .from('parties')
          .update({'title': newTitle}).eq('id', partyId);

      final verify = await adminClient
          .from('parties')
          .select('title')
          .eq('id', partyId)
          .single();
      expect(verify['title'], equals(newTitle));
    });

    test('Guest should NOT be able to update party', () async {
      final client = createUserClient(guestId);

      // Attempt update
      final res = await client
          .from('parties')
          .update({'title': 'Hacked by Guest'})
          .eq('id', partyId)
          .select();

      expect(res, isEmpty, reason: 'Guest should not update party');

      // Verify content
      final verify = await adminClient
          .from('parties')
          .select('title')
          .eq('id', partyId)
          .single();
      expect(verify['title'], isNot(equals('Hacked by Guest')));
    });

    test('Everyone should be able to read active parties', () async {
      final client = createUserClient(guestId);
      final data =
          await client.from('parties').select().eq('id', partyId).maybeSingle();
      expect(data, isNotNull);
    });
  });
}
