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

    final email = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(email);
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 02: Browse', () {
    testWidgets('이벤트 피드를 조회할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      final events = await client
          .from('events')
          .select('id, title, status')
          .eq('status', 'scheduled')
          .order('created_at', ascending: false)
          .limit(5) as List;

      expect(events, isNotEmpty, reason: 'Dev server should have events');

      final firstEvent = events.first as Map<String, dynamic>;
      expect(firstEvent['id'], isNotNull);
      expect(firstEvent['title'], isNotNull);
      expect(firstEvent['status'], equals('scheduled'));
    });

    testWidgets('이벤트에 파티 관계가 포함된다', (tester) async {
      final client = Supabase.instance.client;

      final event = await client
          .from('events')
          .select('id, party:parties(title)')
          .eq('status', 'scheduled')
          .limit(1)
          .single();

      final party = event['party'] as Map<String, dynamic>?;
      expect(party, isNotNull, reason: 'Event should have a party relation');
      expect(party!['title'], isNotNull);
    });

    testWidgets('파티에 파트너 관계가 포함된다', (tester) async {
      final client = Supabase.instance.client;

      final event = await client
          .from('events')
          .select('id, party:parties(partner:partners(name))')
          .eq('status', 'scheduled')
          .limit(1)
          .single();

      final party = event['party'] as Map<String, dynamic>;
      final partner = party['partner'] as Map<String, dynamic>?;
      expect(partner, isNotNull, reason: 'Party should have a partner');
      expect(partner!['name'], isNotNull);
    });
  });
}
