import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 16: RLS Isolation — Verify cross-user data access is blocked.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late String userBId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    // Get two distinct test users (male and female)
    final emailA = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(emailA);
    await signOut();

    final emailB = await getTestUserEmail(adminClient, gender: 'female');
    await signInAsTestUser(emailB);
    userBId = Supabase.instance.client.auth.currentUser!.id;
    await signOut();

    // Sign in as user A for the tests
    await signInAsTestUser(emailA);
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 16: RLS Isolation', () {
    testWidgets('유저 A는 유저 B의 event_applications를 조회할 수 없다', (tester) async {
      final client = Supabase.instance.client;

      // User A queries user B's applications — RLS should return empty
      final apps = await client
          .from('event_applications')
          .select()
          .eq('user_id', userBId);

      expect(
        apps,
        isEmpty,
        reason: "User A should not see User B's applications",
      );
    });

    testWidgets('유저 A는 유저 B의 user_profiles를 수정할 수 없다', (tester) async {
      final client = Supabase.instance.client;

      // Attempt to update user B's profile — RLS should block
      try {
        await client
            .from('user_profiles')
            .update({'bio': 'RLS bypass attempt'}).eq('id', userBId);

        // If no error, verify the update didn't actually take effect
        final profile = await adminClient
            .from('user_profiles')
            .select('bio')
            .eq('id', userBId)
            .single();
        expect(
          profile['bio'],
          isNot(equals('RLS bypass attempt')),
          reason: "User A should not be able to modify User B's profile",
        );
      } on PostgrestException catch (e) {
        // RLS violation — expected behavior
        expect(e.code, isNotNull);
      }
    });

    testWidgets('유저 A는 유저 B의 프로필을 직접 조회할 수 없다', (tester) async {
      final client = Supabase.instance.client;

      // RLS policy: "Users can read own profile" — self-only
      final profiles =
          await client.from('user_profiles').select().eq('id', userBId);

      expect(
        profiles,
        isEmpty,
        reason: "User A should not see User B's profile (self-only RLS)",
      );
    });

    testWidgets('인증되지 않은 요청은 보호된 테이블에 접근할 수 없다', (tester) async {
      // Sign out to become unauthenticated
      await signOut();

      final client = Supabase.instance.client;

      try {
        final result = await client.from('event_applications').select();
        // Anon should get empty or error
        expect(
          result,
          isEmpty,
          reason:
              'Unauthenticated request should not access event_applications',
        );
      } on PostgrestException catch (e) {
        // Permission denied — expected
        expect(e.code, isNotNull);
      }

      // Re-authenticate for subsequent tests/teardown
      final emailA = await getTestUserEmail(adminClient, gender: 'male');
      await signInAsTestUser(emailA);
    });
  });
}
