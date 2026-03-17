import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 02: Browse — Explore events and parties.
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

  group('CUJ 02: Browse', () {
    testWidgets('Should browse events and parties', (tester) async {
      // 1. Sign in
      final email = await getTestUserEmail(adminClient, gender: 'male');
      await signInAsTestUser(email);

      final client = Supabase.instance.client;

      // 2. Fetch event feed (scheduled events)
      final events = await client
          .from('events')
          .select('*, party:parties(title, partner:partners(name))')
          .eq('status', 'scheduled')
          .order('created_at', ascending: false)
          .limit(5) as List;

      expect(events, isNotEmpty, reason: 'Dev server should have events');

      // 3. Verify event data structure
      final firstEvent = events.first as Map<String, dynamic>;
      expect(firstEvent['id'], isNotNull);
      expect(firstEvent['title'], isNotNull);
      expect(firstEvent['status'], equals('scheduled'));

      // 4. Verify party relation
      final party = firstEvent['party'] as Map<String, dynamic>?;
      expect(party, isNotNull, reason: 'Event should have a party relation');
      expect(party!['title'], isNotNull);

      // 5. Verify partner relation (nested)
      final partner = party['partner'] as Map<String, dynamic>?;
      expect(partner, isNotNull, reason: 'Party should have a partner');
      expect(partner!['name'], isNotNull);
    });
  });
}
