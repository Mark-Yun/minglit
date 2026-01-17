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

  group('Partner Permission Tests', () {
    late String ownerId;
    late String partnerId;
    late String otherUserId;

    setUpAll(() async {
      // Get Owner and Partner
      final p1 = await adminClient.from('partners').select('id, partner_member_permissions(user_id)').limit(1).single();
      partnerId = p1['id'];
      ownerId = (p1['partner_member_permissions'] as List).first['user_id'];

      // Get unrelated user
      final u = await adminClient.from('user_profiles').select().eq('username', 'user_1').single();
      otherUserId = u['id'];
    });

    test('Owner should be able to update partner info', () async {
      final client = createUserClient(ownerId);
      await client.from('partners').update({'introduction': 'Updated Intro'}).eq('id', partnerId);
      
      final verify = await adminClient.from('partners').select('introduction').eq('id', partnerId).single();
      expect(verify['introduction'], equals('Updated Intro'));
    });

    test('Unrelated user should NOT be able to update partner info', () async {
      final client = createUserClient(otherUserId);
      final res = await client.from('partners').update({'introduction': 'Hacked'}).eq('id', partnerId).select();
      
      expect(res, isEmpty);
    });
  });
}
