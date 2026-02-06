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

  group('Refund Trigger Tests', () {
    late String testUserId;
    late String testPartnerId;
    late String testVerificationId;
    late String testEventId;
    late String testTicketId;

    setUpAll(() async {
      print('🚀 [Setup] Fetching seeded data...');

      // Get Test User via Helper
      testUserId = await getMale25VerifiedUserId(adminClient);

      // Get Event & Ticket
      final event = await adminClient
          .from('events')
          .select('id, tickets(id), party:parties(partner_id)')
          .limit(1)
          .single();
      testEventId = event['id'];
      testTicketId = event['tickets'][0]['id'];
      testPartnerId = event['party']['partner_id'];

      // Get Verification
      final verif =
          await adminClient.from('verifications').select().limit(1).single();
      testVerificationId = verif['id'];

      // Cleanup existing data for clean state
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
        'Rejection Cascade: Submission Rejected -> App Rejected + Reason + Refund Requested',
        () async {
      final paymentId = 'REFUND_TEST_${Random().nextInt(9999)}';

      // 1. Create Application (Pending Review)
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
      final appId = appRes['id'];

      // 2. Create Submission (Linked to App)
      final subRes = await adminClient
          .from('verification_submissions')
          .insert({
            'partner_id': testPartnerId,
            'user_id': testUserId,
            'verification_id': testVerificationId,
            'application_id': appId,
            'status': 'pending',
            'snapshot_data': {'proof': 'fake.jpg'},
          })
          .select()
          .single();
      final subId = subRes['id'];

      print('📝 Created Application ($appId) and Submission ($subId)');

      // 3. Update Submission Status to 'rejected' with comment
      const rejectionReason = 'Invalid ID Proof';
      print('🚫 Rejecting submission with reason: $rejectionReason');

      await adminClient
          .from('verification_submissions')
          .update({'status': 'rejected', 'admin_comment': rejectionReason}).eq(
              'id', subId,);

      // Allow trigger propagation (DB trigger is sync, but net call is async/blocking inside trigger?
      // pg_net is async, but update to refund_status happens in trigger.
      // Wait a bit just in case.)
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Verify Application State
      final updatedApp = await adminClient
          .from('event_applications')
          .select()
          .eq('id', appId)
          .single();

      // A. Status Rejected?
      expect(updatedApp['status'], equals('rejected'),
          reason: 'Application should be rejected',);

      // B. Reason Synced?
      expect(updatedApp['rejection_reason'], equals(rejectionReason),
          reason: 'Rejection reason should be synced',);

      // C. Refund Requested?
      // Note: 'refund_status' is updated by 'on_application_rejected' trigger which fires AFTER 'handle_verification_approval' updates 'event_applications'.
      // Order:
      // 1. verification update -> trigger 'on_submission_status_change' -> updates 'event_applications'
      // 2. 'event_applications' update -> trigger 'on_application_rejected' -> calls net.http_post AND updates 'refund_status'.

      expect(updatedApp['refund_status'], equals('requested'),
          reason: 'Refund status should be requested',);

      print('✅ Refund trigger verified successfully!');
    });
  });
}
