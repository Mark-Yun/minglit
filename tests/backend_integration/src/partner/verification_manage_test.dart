import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:supabase/supabase.dart';
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

  group('Verification Management Tests', () {
    late String ownerId;
    late String partnerId;

    setUpAll(() async {
      final p1 = await adminClient
          .from('partners')
          .select('id, partner_member_permissions(user_id)')
          .limit(1)
          .single();
      partnerId = p1['id'] as String;
      ownerId =
          (p1['partner_member_permissions'] as List).first['user_id'] as String;
    });

    test('Owner should be able to create verification', () async {
      final client = createUserClient(ownerId);
      final res = await client
          .from('verifications')
          .insert({
            'partner_id': partnerId,
            'category': 'etc',
            'internal_name': 'test_verify',
            'display_name': 'Test Verification',
            'form_schema': [],
          })
          .select()
          .single();

      expect(res['partner_id'], equals(partnerId));

      // Cleanup
      await adminClient
          .from('verifications')
          .delete()
          .eq('id', res['id'] as Object);
    });
  });
}
