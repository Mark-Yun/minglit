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

  group('S02: Rejection and Refund Scenario', () {
    late String testUserId;
    late String testPartnerId;
    late String testEventId;
    late String testTicketId;
    late String testVerificationId;

    setUpAll(() async {
      testUserId = await getMale25VerifiedUserId(adminClient);
      final eventCtx = await findScheduledEvent(adminClient);
      testEventId = eventCtx.eventId;
      testTicketId = eventCtx.ticketId;
      testPartnerId = eventCtx.partnerId;
      testVerificationId = await getCareerVerificationId(adminClient);

      // Cleanup
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
        'Rejection cascade: submission rejected → app rejected + refund requested',
        () async {
      final paymentId = 'imp_refund_${Random().nextInt(99999)}';

      // Step 1: Create application with payment
      final appRes = await adminClient
          .from('event_applications')
          .insert({
            'event_id': testEventId,
            'ticket_id': testTicketId,
            'user_id': testUserId,
            'status': 'pending_review',
            'payment_id': paymentId,
            'payment_amount': 5000,
          })
          .select()
          .single();
      final appId = appRes['id'] as String;

      // Step 2: Create verification submission
      final subRes = await adminClient
          .from('verification_submissions')
          .insert({
            'partner_id': testPartnerId,
            'user_id': testUserId,
            'verification_id': testVerificationId,
            'application_id': appId,
            'status': 'pending',
            'snapshot_data': {'proof': 'test.jpg'},
          })
          .select()
          .single();
      final subId = subRes['id'] as String;

      // Step 3: Reject submission → triggers cascade
      await adminClient
          .from('verification_submissions')
          .update({'status': 'rejected', 'admin_comment': 'Invalid proof'}).eq(
              'id', subId);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Step 4: Verify cascade results
      final updatedApp = await adminClient
          .from('event_applications')
          .select()
          .eq('id', appId)
          .single();

      expect(updatedApp['status'], equals('rejected'),
          reason: 'Application should be rejected');
      expect(updatedApp['rejection_reason'], equals('Invalid proof'),
          reason: 'Rejection reason should be synced');
      expect(updatedApp['refund_status'], equals('requested'),
          reason: 'Refund should be requested when payment exists');
    });

    test('Edge case: rejection without payment → refund_status stays none',
        () async {
      // Create application WITHOUT payment_id
      final appRes = await adminClient
          .from('event_applications')
          .insert({
            'event_id': testEventId,
            'ticket_id': testTicketId,
            'user_id': testUserId,
            'status': 'pending_review',
          })
          .select()
          .single();
      final appId = appRes['id'] as String;

      // Directly reject (no submission needed)
      await adminClient
          .from('event_applications')
          .update({'status': 'rejected', 'rejection_reason': 'No payment'}).eq(
              'id', appId);

      await Future<void>.delayed(const Duration(milliseconds: 300));

      final updatedApp = await adminClient
          .from('event_applications')
          .select()
          .eq('id', appId)
          .single();

      expect(updatedApp['refund_status'], equals('none'),
          reason: 'No payment → refund_status should remain none');
    });
  });
}
