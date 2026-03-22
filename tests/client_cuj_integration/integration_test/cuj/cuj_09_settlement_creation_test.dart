import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 09: Settlement Creation — Event completion triggers settlement record.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String testUserId;
  late String verificationId;
  late String applicationId;
  final paymentId = 'E2E_SETTLE_${Random().nextInt(99999)}';

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    // Find a fresh scheduled event (not previously completed)
    eventCtx = await findScheduledEvent(adminClient);
    final email = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(email);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
    verificationId = await getCareerVerificationId(adminClient);

    await _cleanup(adminClient, testUserId, eventCtx.eventId);

    // Create a paid application
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
          'data': {'company': 'E2E Settlement Corp', 'position': 'QA'},
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
  });

  tearDownAll(() async {
    // Restore event to scheduled for other tests
    try {
      await adminClient
          .from('events')
          .update({'status': 'scheduled'})
          .eq('id', eventCtx.eventId);
    } on Object catch (_) {}
    // Delete settlement
    try {
      await adminClient
          .from('settlements')
          .delete()
          .eq('event_id', eventCtx.eventId);
    } on Object catch (_) {}
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
    await signOut();
  });

  group('CUJ 09: Settlement Creation', () {
    testWidgets('이벤트 완료 시 settlement가 자동 생성된다', (tester) async {
      // Complete the event (triggers create_settlement_on_event_completion)
      await adminClient
          .from('events')
          .update({'status': 'completed'})
          .eq('id', eventCtx.eventId);

      // Settlement should be created by trigger
      final settlement = await retry(() async {
        final res = await adminClient
            .from('settlements')
            .select()
            .eq('event_id', eventCtx.eventId)
            .maybeSingle();
        if (res == null) throw Exception('Settlement not yet created');
        return res;
      });

      expect(settlement, isNotNull);
      expect(settlement['event_id'], equals(eventCtx.eventId));
      expect(settlement['partner_id'], equals(eventCtx.partnerId));
      expect(settlement['status'], equals('pending'));
    });

    testWidgets('settlement의 매출 금액이 올바르다', (tester) async {
      final settlement = await adminClient
          .from('settlements')
          .select()
          .eq('event_id', eventCtx.eventId)
          .single();

      // total_sales should include our 15000 payment
      expect(settlement['total_sales'] as int, greaterThanOrEqualTo(15000));
      expect(settlement['net_amount'] as int, isA<int>());
      expect(settlement['pg_fee'] as int, isA<int>());
      expect(settlement['platform_fee'] as int, isA<int>());
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
