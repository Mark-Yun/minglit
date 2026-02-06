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

  group('Auto-Approval Trigger Logic Tests', () {
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

      // Cleanup existing data for idempotency
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
        'Chain Reaction: Verify Approved -> Application Approved -> Ticket Issued',
        () async {
      final paymentId = 'TRG_${Random().nextInt(9999)}';

      // 1. Create Application (Pending Review)
      final appRes = await adminClient
          .from('event_applications')
          .insert({
            'event_id': testEventId,
            'ticket_id': testTicketId,
            'user_id': testUserId,
            'status': 'pending_review',
            'payment_id': paymentId,
            'payment_amount': 1000,
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
            'snapshot_data': {'company': 'Test Trigger Corp'},
          })
          .select()
          .single();
      final subId = subRes['id'];

      print('📝 Created Application ($appId) and Submission ($subId)');

      // 3. Update Submission Status to 'approved'
      print('👮 Approving submission...');
      await adminClient
          .from('verification_submissions')
          .update({'status': 'approved'}).eq('id', subId);

      // Allow trigger propagation
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Verify Chain Reaction

      // A. partner_verified_users created?
      final verifiedUser = await adminClient
          .from('partner_verified_users')
          .select()
          .eq('submission_id', subId)
          .maybeSingle();
      expect(verifiedUser, isNotNull,
          reason: 'partner_verified_users should be created via trigger',);

      // B. event_applications status changed?
      final updatedApp = await adminClient
          .from('event_applications')
          .select('status')
          .eq('id', appId)
          .single();
      expect(updatedApp['status'], equals('approved'),
          reason: 'Application should be auto-approved',);

      // C. event_participants ticket issued?
      final participant = await adminClient
          .from('event_participants')
          .select()
          .eq('application_id', appId)
          .maybeSingle();
      expect(participant, isNotNull,
          reason: 'Ticket should be issued automatically',);
      expect(participant!['ticket_code'], isNotNull);

      print('🎉 Chain reaction verified successfully!');
    });

    test('Revoke: Changing submission to rejected should remove verified_user',
        () async {
      // 1. Find an approved submission for our user
      final subRes = await adminClient
          .from('verification_submissions')
          .select()
          .eq('user_id', testUserId)
          .eq('status', 'approved')
          .limit(1)
          .maybeSingle();

      if (subRes == null) {
        print('⚠️ No approved submission found, skipping revoke test.');
        return;
      }
      final subId = subRes['id'];

      // 2. Revoke approval
      print('👮 Revoking approval for $subId...');
      await adminClient
          .from('verification_submissions')
          .update({'status': 'rejected'}).eq('id', subId);

      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Verify partner_verified_users removed
      final verifiedUser = await adminClient
          .from('partner_verified_users')
          .select()
          .eq('submission_id', subId)
          .maybeSingle();
      expect(verifiedUser, isNull,
          reason: 'partner_verified_users should be removed on revoke',);

      print('✅ Revoke verified successfully!');
    });
  });
}
