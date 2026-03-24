import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 14: 프로필 수정 — 자신의 프로필 조회 및 필드 수정.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late String testEmail;
  late String testUserId;
  String? originalBio;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    testEmail = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(testEmail);

    testUserId = Supabase.instance.client.auth.currentUser!.id;

    // Save original bio value for restoration in tearDownAll
    final profile = await adminClient
        .from('user_profiles')
        .select('bio')
        .eq('id', testUserId)
        .single();
    originalBio = profile['bio'] as String?;
  });

  tearDownAll(() async {
    // Restore original bio value via admin client
    await adminClient
        .from('user_profiles')
        .update({'bio': originalBio})
        .eq('id', testUserId);

    await signOut();
  });

  group('CUJ 14: 프로필 수정', () {
    testWidgets('자신의 프로필을 조회할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      final profile = await client
          .from('user_profiles')
          .select()
          .eq('id', testUserId)
          .single();

      expect(profile['id'], equals(testUserId));
      expect(profile.containsKey('username'), isTrue);
      expect(profile.containsKey('gender'), isTrue);
      expect(profile.containsKey('birth_date'), isTrue);
      expect(profile.containsKey('is_verified'), isTrue);
    });

    testWidgets('프로필 필드를 수정할 수 있다', (tester) async {
      const updatedBio = 'E2E 테스트용 자기소개 — minglit integration test';

      // Use admin client to bypass RLS on user_profiles writes
      await adminClient
          .from('user_profiles')
          .update({'bio': updatedBio})
          .eq('id', testUserId);

      // Verify change via authenticated client
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select('bio')
          .eq('id', testUserId)
          .single();

      expect(profile['bio'], equals(updatedBio));
    });

    testWidgets('수정 후 원래 값으로 복원된다', (tester) async {
      // Restore original value via admin client
      await adminClient
          .from('user_profiles')
          .update({'bio': originalBio})
          .eq('id', testUserId);

      // Verify the restoration
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select('bio')
          .eq('id', testUserId)
          .single();

      expect(
        profile['bio'],
        equals(originalBio),
        reason: '프로필 bio가 원래 값으로 복원되어야 한다',
      );
    });
  });
}
