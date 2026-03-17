import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 06: Partner — Manage events as a partner owner.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    eventCtx = await findScheduledEvent(adminClient);
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 06: Partner', () {
    testWidgets('Should access events and applications as partner owner',
        (tester) async {
      // 1. Sign in as partner owner
      final ownerEmail = await getPartnerOwnerEmail(
        adminClient,
        ownerId: eventCtx.ownerId,
      );
      await signInAsTestUser(ownerEmail);

      final client = Supabase.instance.client;

      // 2. Query partner's events
      final events = await client
          .from('events')
          .select('id, title, status')
          .eq('party_id', await _getPartyId(adminClient, eventCtx.partnerId))
          .order('created_at', ascending: false)
          .limit(5) as List;

      expect(
        events,
        isNotEmpty,
        reason: 'Partner should have at least one event',
      );

      final firstEvent = events.first as Map<String, dynamic>;
      expect(firstEvent['id'], isNotNull);
      expect(firstEvent['title'], isNotNull);

      // 3. Query applications for the event
      final applications = await client
          .from('event_applications')
          .select('id, status, user_id')
          .eq('event_id', firstEvent['id'] as String) as List;

      // Applications list may be empty, but the query should succeed
      expect(applications, isList);

      // 4. If applications exist, verify data structure
      if (applications.isNotEmpty) {
        final firstApp = applications.first as Map<String, dynamic>;
        expect(firstApp.containsKey('id'), isTrue);
        expect(firstApp.containsKey('status'), isTrue);
        expect(firstApp.containsKey('user_id'), isTrue);
      }
    });
  });
}

/// Gets a party ID for a given partner.
Future<String> _getPartyId(
  SupabaseClient admin,
  String partnerId,
) async {
  final res = await admin
      .from('parties')
      .select('id')
      .eq('partner_id', partnerId)
      .limit(1)
      .single();
  return res['id'] as String;
}
