import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 01: Authentication — Sign in and verify session + profile.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 01: Auth', () {
    testWidgets('Should sign in and read own profile', (tester) async {
      // 1. Find test user email
      final email = await getTestUserEmail(adminClient, gender: 'male');

      // 2. Sign in
      await signInAsTestUser(email);

      // 3. Verify session exists
      final currentUser = Supabase.instance.client.auth.currentUser;
      expect(currentUser, isNotNull, reason: 'Should have an active session');
      expect(currentUser!.email, equals(email));

      // 4. Read own profile (through authenticated client — RLS applied)
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', currentUser.id)
          .single();

      expect(profile['id'], equals(currentUser.id));
      expect(profile['username'], isNotNull);
      expect(profile['gender'], equals('male'));
    });
  });
}
