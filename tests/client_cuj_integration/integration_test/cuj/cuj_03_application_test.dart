import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 03: Application — Apply to event, get approved, become participant.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String testUserId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    eventCtx = await findScheduledEvent(adminClient);
    final email = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(email);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
  });

  tearDownAll(() async {
    // Best-effort cleanup — don't fail teardown
    try {
      await adminClient
          .from('event_participants')
          .delete()
          .eq('user_id', testUserId)
          .eq('event_id', eventCtx.eventId);
    } on Object catch (_) {}
    try {
      final appId = await _getApplicationId(
        adminClient,
        testUserId,
        eventCtx.eventId,
      );
      if (appId != null) {
        await adminClient
            .from('verification_submissions')
            .delete()
            .eq('application_id', appId);
        await adminClient.from('event_applications').delete().eq('id', appId);
      }
    } on Object catch (_) {}
    await signOut();
  });

  group('CUJ 03: Application', () {
    testWidgets('Should complete full application flow', (tester) async {
      final client = Supabase.instance.client;

      // 1. Cleanup any existing application (idempotent)
      try {
        await adminClient
            .from('event_participants')
            .delete()
            .eq('user_id', testUserId)
            .eq('event_id', eventCtx.eventId);
        await adminClient
            .from('event_applications')
            .delete()
            .eq('user_id', testUserId)
            .eq('event_id', eventCtx.eventId);
      } on Object catch (_) {}

      // 2. Get verification ID
      final verificationId = await getCareerVerificationId(adminClient);

      // 3. Apply to event (atomic RPC)
      final appId = await client.rpc<dynamic>(
        'apply_event',
        params: {
          'p_event_id': eventCtx.eventId,
          'p_ticket_id': eventCtx.ticketId,
          'p_user_id': testUserId,
          'p_payment_id': 'E2E_PAY_${Random().nextInt(99999)}',
          'p_payment_amount': 1000,
          'p_verification_data': {
            'partner_id': eventCtx.partnerId,
            'verification_id': verificationId,
            'data': {'company': 'E2E Test Corp', 'position': 'Tester'},
          },
        },
      );
      expect(appId, isNotNull, reason: 'Application should be created');

      // 4. Verify pending status
      final app = await client
          .from('event_applications')
          .select()
          .eq('id', appId as Object)
          .single();
      expect(app['status'], equals('pending_review'));

      // 5. Admin approves verification
      await adminClient
          .from('verification_submissions')
          .update({'status': 'approved'}).eq('application_id', appId);

      // 6. Wait for DB trigger to process
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 7. Verify approved + participant created
      final updatedApp = await adminClient
          .from('event_applications')
          .select()
          .eq('id', appId)
          .single();
      expect(updatedApp['status'], equals('approved'));

      final participant = await adminClient
          .from('event_participants')
          .select()
          .eq('application_id', appId)
          .maybeSingle();
      expect(participant, isNotNull, reason: 'Participant should be created');
      expect(participant!['ticket_code'], isNotNull);
    });
  });
}

Future<String?> _getApplicationId(
  SupabaseClient admin,
  String userId,
  String eventId,
) async {
  final res = await admin
      .from('event_applications')
      .select('id')
      .eq('user_id', userId)
      .eq('event_id', eventId)
      .maybeSingle();
  return res?['id'] as String?;
}
