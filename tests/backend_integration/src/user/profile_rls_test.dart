import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

import '../utils/test_config.dart';

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

  group('User Profile RLS Tests', () {
    late String user1Id;
    late String user2Id;

    setUpAll(() async {
      print('🚀 [Setup] Fetching users...');
      final u1 = await adminClient
          .from('user_profiles')
          .select()
          .eq('username', 'user_25_m_ok')
          .single();
      final u2 = await adminClient
          .from('user_profiles')
          .select()
          .eq('username', 'user_25_f_ok')
          .single();
      user1Id = u1['id'];
      user2Id = u2['id'];

      // Ensure initial state
      await adminClient.from('user_profiles').update({
        'name': 'Original User 1',
        'is_verified': false,
      }).eq('id', user1Id);

      await adminClient.from('user_profiles').update({
        'name': 'Original User 2',
      }).eq('id', user2Id);
    });

    test('User 1 should read own profile', () async {
      final client1 = createUserClient(user1Id);
      final data = await client1
          .from('user_profiles')
          .select()
          .eq('id', user1Id)
          .single();
      expect(data['id'], equals(user1Id));
    });

    test('User 1 should read other profiles (Public)', () async {
      final client1 = createUserClient(user1Id);
      final data = await client1
          .from('user_profiles')
          .select()
          .eq('id', user2Id)
          .single();
      expect(data['id'], equals(user2Id));
    });

    test('User 1 should update own profile', () async {
      final client1 = createUserClient(user1Id);
      await client1
          .from('user_profiles')
          .update({'name': 'Updated User 1'}).eq('id', user1Id);

      final verify = await adminClient
          .from('user_profiles')
          .select('name')
          .eq('id', user1Id)
          .single();
      expect(verify['name'], equals('Updated User 1'));
    });

    test('User 1 should NOT update other profiles', () async {
      final client1 = createUserClient(user1Id);
      final res = await client1
          .from('user_profiles')
          .update({'name': 'Hacked User 2'})
          .eq('id', user2Id)
          .select();

      expect(res, isEmpty);

      final verify = await adminClient
          .from('user_profiles')
          .select('name')
          .eq('id', user2Id)
          .single();
      expect(verify['name'], equals('Original User 2'));
    });

    // 🚨 Critical Security Test
    test('User 1 should NOT be able to update protected fields (is_verified)',
        () async {
      final client1 = createUserClient(user1Id);

      // Attempt to self-verify
      // Note: RLS allows update if (auth.uid() = id).
      // It does NOT check columns by default unless we use column-level privileges or check triggers.
      // So this test is EXPECTED TO FAIL (Security Hole) initially if we haven't protected the column.

      try {
        await client1
            .from('user_profiles')
            .update({'is_verified': true}).eq('id', user1Id);
      } catch (e) {
        // If error thrown (e.g. by trigger), that's good.
      }

      final verify = await adminClient
          .from('user_profiles')
          .select('is_verified')
          .eq('id', user1Id)
          .single();

      // If verify['is_verified'] is true, we have a security hole.
      // We expect it to be false.
      expect(verify['is_verified'], isFalse,
          reason: 'Security Hole: User was able to update is_verified!');
    });
  });
}
