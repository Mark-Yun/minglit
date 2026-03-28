import 'dart:math';
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

  group('S01: Payment Verification Scenario', () {
    late String testUserId;
    late String testEventId;
    late String testTicketId;

    setUpAll(() async {
      testUserId = await getMale25VerifiedUserId(adminClient);
      final eventCtx = await findScheduledEvent(adminClient);
      testEventId = eventCtx.eventId;
      testTicketId = eventCtx.ticketId;

      // Cleanup existing data
      await adminClient
          .from('event_participants')
          .delete()
          .eq('user_id', testUserId)
          .eq('event_id', testEventId);
      await adminClient
          .from('event_applications')
          .delete()
          .eq('user_id', testUserId)
          .eq('event_id', testEventId);
    });

    test(
        'apply_event (no verification) → status=paid → approved → ticket issued',
        () async {
      final paymentId = 'imp_scenario_${Random().nextInt(99999)}';

      // Step 1: apply_event RPC (no verification_data → status='paid')
      final appId = await adminClient.rpc<dynamic>('apply_event', params: {
        'p_event_id': testEventId,
        'p_ticket_id': testTicketId,
        'p_user_id': testUserId,
        'p_payment_id': paymentId,
        'p_payment_amount': 5000,
      }) as String;

      expect(appId, isNotNull,
          reason: 'apply_event should return application id');

      // Step 2: Verify application status = 'paid'
      final app = await adminClient
          .from('event_applications')
          .select()
          .eq('id', appId)
          .single();
      expect(app['status'], equals('paid'),
          reason: 'No verification_data → status=paid');

      // Step 3: Update to 'approved' → triggers issue_ticket_on_approval
      await adminClient
          .from('event_applications')
          .update({'status': 'approved'}).eq('id', appId);

      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Step 4: Verify ticket issued in event_participants
      final participants = await adminClient
          .from('event_participants')
          .select()
          .eq('event_id', testEventId)
          .eq('user_id', testUserId);

      expect(participants, isNotEmpty,
          reason: 'Ticket should be issued after approval');

      // Step 5: Verify ticket_code format (8-char uppercase hex)
      final ticketCode = participants.first['ticket_code'] as String;
      expect(ticketCode.length, equals(8),
          reason: 'ticket_code should be 8 chars');
      expect(
        RegExp(r'^[0-9A-F]{8}$').hasMatch(ticketCode),
        isTrue,
        reason: 'ticket_code should be uppercase hex',
      );
    });
  });
}
