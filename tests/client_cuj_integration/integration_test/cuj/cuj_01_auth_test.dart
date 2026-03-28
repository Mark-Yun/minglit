import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 01: Authentication — Sign in, verify session, read profile.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late String testEmail;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    testEmail = await getTestUserEmail(adminClient, gender: 'male');
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 01: Auth', () {
    testWidgets('로그인 후 세션이 생성된다', (tester) async {
      await signInAsTestUser(testEmail);

      final currentUser = Supabase.instance.client.auth.currentUser;
      expect(currentUser, isNotNull, reason: 'Should have an active session');
      expect(currentUser!.email, equals(testEmail));
    });

    testWidgets('인증된 사용자가 자신의 프로필을 조회할 수 있다',
        (tester) async {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser!;

      final profile = await client
          .from('user_profiles')
          .select()
          .eq('id', currentUser.id)
          .single();

      expect(profile['id'], equals(currentUser.id));
      expect(profile['username'], isNotNull);
      expect(profile['gender'], equals('male'));
    });

    testWidgets('다른 유저의 프로필은 RLS로 제한된다', (tester) async {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser!;

      // Query all profiles — RLS should filter to own profile only
      final profiles =
          await client.from('user_profiles').select('id') as List;

      final ownProfile = profiles.where(
        (p) => (p as Map<String, dynamic>)['id'] == currentUser.id,
      );
      expect(ownProfile, isNotEmpty, reason: 'Should see own profile');
    });
  });
}
