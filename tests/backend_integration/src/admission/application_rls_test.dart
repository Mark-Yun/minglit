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

  group('Event Application RLS Tests', () {
    late String user1Id;
    late String user2Id;
    late String app1Id;
    late String app2Id;

    setUpAll(() async {
      print('🚀 [Setup] Fetching users and creating test applications...');

      // 1. Get User 1 (Male) and User 2 (Female) via Helpers
      user1Id = await getMale25VerifiedUserId(adminClient);
      user2Id = await getFemale25VerifiedUserId(adminClient);

      // 2. Get shared event and ticket
      final event = await adminClient
          .from('events')
          .select('id, tickets(id)')
          .limit(1)
          .single();
      final eventId = event['id'];
      final ticketId = event['tickets'][0]['id'];

      // 3. Create Applications via Admin (Bypass RLS)
      // Delete existing to avoid unique constraint (Delete participants first due to FK)
      await adminClient
          .from('event_participants')
          .delete()
          .inFilter('user_id', [user1Id, user2Id]);
      await adminClient
          .from('event_applications')
          .delete()
          .inFilter('user_id', [user1Id, user2Id]);

      final res1 = await adminClient
          .from('event_applications')
          .insert({
            'event_id': eventId,
            'ticket_id': ticketId,
            'user_id': user1Id,
            'status': 'pending',
          })
          .select()
          .single();
      app1Id = res1['id'];

      final res2 = await adminClient
          .from('event_applications')
          .insert({
            'event_id': eventId,
            'ticket_id': ticketId,
            'user_id': user2Id,
            'status': 'pending',
          })
          .select()
          .single();
      app2Id = res2['id'];

      print('✅ [Setup] Ready. App1: $app1Id (User1), App2: $app2Id (User2)');
    });

    test('User 1 should see their own application', () async {
      final client1 = createUserClient(user1Id);
      final data = await client1
          .from('event_applications')
          .select()
          .eq('id', app1Id)
          .maybeSingle();

      expect(data, isNotNull);
      expect(data!['id'], equals(app1Id));
    });

    test('User 1 should NOT see User 2\'s application', () async {
      final client1 = createUserClient(user1Id);
      final data = await client1
          .from('event_applications')
          .select()
          .eq('id', app2Id)
          .maybeSingle();

      expect(data, isNull, reason: 'RLS should hide other users applications');
    });

    test('User 1 should NOT be able to update User 2\'s application', () async {
      final client1 = createUserClient(user1Id);

      // Attempt to change status of User 2's app
      final res = await client1
          .from('event_applications')
          .update({'status': 'paid'})
          .eq('id', app2Id)
          .select();

      expect(res, isEmpty,
          reason: 'RLS should prevent updating other users data',);

      // Verify via admin that it remains pending
      final verify = await adminClient
          .from('event_applications')
          .select('status')
          .eq('id', app2Id)
          .single();
      expect(verify['status'], equals('pending'));
    });

    test('User 1 should be able to update their own application (message)',
        () async {
      final client1 = createUserClient(user1Id);

      await client1
          .from('event_applications')
          .update({'message': 'Hello from User 1'}).eq('id', app1Id);

      final verify = await adminClient
          .from('event_applications')
          .select('message')
          .eq('id', app1Id)
          .single();
      expect(verify['message'], equals('Hello from User 1'));
    });
  });
}
