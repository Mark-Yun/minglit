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
  late String partyId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    eventCtx = await findScheduledEvent(adminClient);

    final ownerEmail = await getPartnerOwnerEmail(
      adminClient,
      ownerId: eventCtx.ownerId,
    );
    await signInAsTestUser(ownerEmail);

    partyId = await _getPartyId(adminClient, eventCtx.partnerId);
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 06: Partner', () {
    testWidgets('파트너 owner가 자신의 이벤트 목록을 조회할 수 있다',
        (tester) async {
      final client = Supabase.instance.client;

      final events = await client
          .from('events')
          .select('id, title, status')
          .eq('party_id', partyId)
          .order('created_at', ascending: false)
          .limit(5) as List;

      expect(events, isNotEmpty,
          reason: 'Partner should have at least one event',);

      final firstEvent = events.first as Map<String, dynamic>;
      expect(firstEvent['id'], isNotNull);
      expect(firstEvent['title'], isNotNull);
    });

    testWidgets('파트너 owner가 이벤트의 신청 목록을 조회할 수 있다',
        (tester) async {
      final client = Supabase.instance.client;

      final applications = await client
          .from('event_applications')
          .select('id, status, user_id')
          .eq('event_id', eventCtx.eventId) as List;

      // Applications list may be empty, but the query should succeed
      expect(applications, isList);
    });

    testWidgets('신청 데이터 구조가 올바르다', (tester) async {
      final client = Supabase.instance.client;

      final applications = await client
          .from('event_applications')
          .select('id, status, user_id')
          .eq('event_id', eventCtx.eventId) as List;

      if (applications.isNotEmpty) {
        final firstApp = applications.first as Map<String, dynamic>;
        expect(firstApp.containsKey('id'), isTrue);
        expect(firstApp.containsKey('status'), isTrue);
        expect(firstApp.containsKey('user_id'), isTrue);
      }
    });
  });
}

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
