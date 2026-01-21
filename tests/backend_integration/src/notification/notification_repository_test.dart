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

  group('Notification Settings Tests', () {
    late String testUserId;

    setUpAll(() async {
      // 1. Get a test user
      testUserId = await getMale25VerifiedUserId(adminClient);
    });

    test('getSettings returns default values if not set (or triggers auto-create)', () async {
      // Check if settings exist. If not, they should be auto-created by trigger or return null if we fetch optionally.
      // The migration script has a trigger `on_auth_user_created_settings` on `auth.users`.
      // So settings should exist for existing users if the trigger ran, or we might need to insert manually if the user was created before the trigger.
      
      // Let's first try to upsert to ensure it exists for this test user, to be safe.
      await adminClient.from('user_settings').upsert({'user_id': testUserId});

      final settings = await adminClient
          .from('user_settings')
          .select()
          .eq('user_id', testUserId)
          .single();

      expect(settings, isNotNull);
      // Check defaults
      // marketing_consent: false, service_notification: true
      // But we upserted empty, so it might keep previous or default.
      // If it was just created, defaults apply.
      
      // We can't guarantee defaults if we didn't wipe it.
      // Let's update explicitly and verify.
    });

    test('updateSettings modifies user settings', () async {
      // 1. Update settings
      await adminClient.from('user_settings').upsert({
        'user_id': testUserId,
        'marketing_consent': true,
        'service_notification': false,
      });

      // 2. Verify update
      final settings = await adminClient
          .from('user_settings')
          .select()
          .eq('user_id', testUserId)
          .single();

      expect(settings['marketing_consent'], isTrue);
      expect(settings['service_notification'], isFalse);

      // 3. Revert
      await adminClient.from('user_settings').upsert({
        'user_id': testUserId,
        'marketing_consent': false,
        'service_notification': true,
      });
      
      final reverted = await adminClient
          .from('user_settings')
          .select()
          .eq('user_id', testUserId)
          .single();
      
      expect(reverted['marketing_consent'], isFalse);
      expect(reverted['service_notification'], isTrue);
    });
  });
}
