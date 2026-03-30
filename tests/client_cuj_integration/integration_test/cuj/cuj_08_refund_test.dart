import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 08: Refund — Cancel payment via Edge Function, verify refund_status.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String testUserId;
  late String verificationId;
  late String applicationId;
  final paymentId = 'E2E_REFUND_${Random().nextInt(99999)}';

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    eventCtx = await findScheduledEvent(adminClient);
    final email = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(email);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
    verificationId = await getCareerVerificationId(adminClient);

    await _cleanup(adminClient, testUserId, eventCtx.eventId);

    // Create a paid application for refund testing
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
          'data': {'company': 'E2E Refund Corp', 'position': 'QA'},
        },
      },
    ) as String;

    // Set status to 'paid' and paid_at (admin)
    await adminClient
        .from('event_applications')
        .update({
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId);
  });

  tearDownAll(() async {
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
    await signOut();
  });

  group('CUJ 08: Refund', () {
    testWidgets('paid 상태에서 환불 요청이 성공한다', (tester) async {
      final client = Supabase.instance.client;

      final response = await client.functions.invoke(
        'payment-cancel',
        body: {
          'payment_id': paymentId,
          'reason': 'E2E test refund',
        },
      );

      expect(response.status, equals(200));
    });

    testWidgets('환불 후 refund_status가 completed로 변경된다', (tester) async {
      final app = await retry(() async {
        final res = await adminClient
            .from('event_applications')
            .select('refund_status, refund_amount')
            .eq('id', applicationId)
            .single();
        if (res['refund_status'] != 'completed') {
          throw Exception('refund not yet completed');
        }
        return res;
      });

      expect(app['refund_status'], equals('completed'));
    });

    testWidgets('이미 환불된 신청에 중복 환불 요청 시 실패한다', (tester) async {
      final client = Supabase.instance.client;

      final response = await client.functions.invoke(
        'payment-cancel',
        body: {
          'payment_id': paymentId,
          'reason': 'Duplicate refund attempt',
        },
      );

      // payment-cancel returns 400 for already_refunded
      expect(response.status, equals(400));
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
