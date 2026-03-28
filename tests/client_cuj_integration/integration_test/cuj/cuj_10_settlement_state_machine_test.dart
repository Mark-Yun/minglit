import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 10: Settlement State Machine — pending → ready transition via cron/RPC.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String testUserId;
  late String verificationId;
  late String applicationId;
  late String settlementId;
  final paymentId = 'E2E_SM_${Random().nextInt(99999)}';

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    eventCtx = await findScheduledEvent(adminClient);
    final email = await getTestUserEmail(adminClient, gender: 'female');
    await signInAsTestUser(email);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
    verificationId = await getCareerVerificationId(adminClient);

    await _cleanup(adminClient, testUserId, eventCtx.eventId);

    // Create paid application
    applicationId = await Supabase.instance.client.rpc<dynamic>(
      'apply_event',
      params: {
        'p_event_id': eventCtx.eventId,
        'p_ticket_id': eventCtx.ticketId,
        'p_user_id': testUserId,
        'p_payment_id': paymentId,
        'p_payment_amount': 15000,
        'p_verification_data': {
          'partner_id': eventCtx.partnerId,
          'verification_id': verificationId,
          'data': {'company': 'E2E StateMachine Corp', 'position': 'QA'},
        },
      },
    ) as String;

    // Set to paid
    await adminClient
        .from('event_applications')
        .update({
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId);

    // Complete event → trigger creates settlement
    await adminClient
        .from('events')
        .update({'status': 'completed'})
        .eq('id', eventCtx.eventId);

    // Get settlement ID
    final settlement = await retry(() async {
      final res = await adminClient
          .from('settlements')
          .select('id')
          .eq('event_id', eventCtx.eventId)
          .maybeSingle();
      if (res == null) throw Exception('Settlement not yet created');
      return res;
    });
    settlementId = settlement['id'] as String;
  });

  tearDownAll(() async {
    try {
      await adminClient
          .from('events')
          .update({'status': 'scheduled'})
          .eq('id', eventCtx.eventId);
    } on Object catch (_) {}
    try {
      await adminClient
          .from('settlements')
          .delete()
          .eq('event_id', eventCtx.eventId);
    } on Object catch (_) {}
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
    await signOut();
  });

  group('CUJ 10: Settlement State Machine', () {
    testWidgets('settlement 초기 상태가 pending이다', (tester) async {
      final settlement = await adminClient
          .from('settlements')
          .select('status')
          .eq('id', settlementId)
          .single();

      expect(settlement['status'], equals('pending'));
    });

    testWidgets('update_settlement_ready_status RPC로 ready 전이 가능하다',
        (tester) async {
      // Simulate 7-day wait by backdating event_date
      await adminClient
          .from('settlements')
          .update({
            'event_date': DateTime.now()
                .subtract(const Duration(days: 8))
                .toIso8601String(),
          })
          .eq('id', settlementId);

      // Call the RPC that cron normally calls
      await adminClient.rpc<void>('update_settlement_ready_status');

      final settlement = await adminClient
          .from('settlements')
          .select('status')
          .eq('id', settlementId)
          .single();

      expect(settlement['status'], equals('ready'));
    });

    testWidgets('ready 상태에서 requested로 전이 가능하다', (tester) async {
      await adminClient
          .from('settlements')
          .update({'status': 'requested'})
          .eq('id', settlementId);

      final settlement = await adminClient
          .from('settlements')
          .select('status')
          .eq('id', settlementId)
          .single();

      expect(settlement['status'], equals('requested'));
    });

    testWidgets('requested에서 completed로 전이 가능하다', (tester) async {
      await adminClient
          .from('settlements')
          .update({'status': 'completed'})
          .eq('id', settlementId);

      final settlement = await adminClient
          .from('settlements')
          .select('status')
          .eq('id', settlementId)
          .single();

      expect(settlement['status'], equals('completed'));
    });
  });
}

Future<void> _cleanup(
  SupabaseClient admin,
  String userId,
  String eventId,
) async {
  try {
    await admin
        .from('event_participants')
        .delete()
        .eq('user_id', userId)
        .eq('event_id', eventId);
  } on Object catch (_) {}
  try {
    final appRes = await admin
        .from('event_applications')
        .select('id')
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .maybeSingle();
    if (appRes != null) {
      final appId = appRes['id'] as String;
      await admin
          .from('verification_submissions')
          .delete()
          .eq('application_id', appId);
      await admin.from('event_applications').delete().eq('id', appId);
    }
  } on Object catch (_) {}
}
