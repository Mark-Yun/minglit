import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 07: Payment Application
/// — Ticket balance check, payment mock, duplicate guard.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String testUserId;
  late String verificationId;
  final paymentId = 'E2E_PAY07_${Random().nextInt(99999)}';

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    eventCtx = await findScheduledEvent(adminClient);
    final email = await getTestUserEmail(adminClient, gender: 'female');
    await signInAsTestUser(email);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
    verificationId = await getCareerVerificationId(adminClient);

    await _cleanup(adminClient, testUserId, eventCtx.eventId);
  });

  tearDownAll(() async {
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
    await signOut();
  });

  group('CUJ 07: Payment Application', () {
    testWidgets('티켓 잔여수량을 조회할 수 있다', (tester) async {
      final ticket = await adminClient
          .from('tickets')
          .select('id, price, quantity, sold_count, status')
          .eq('id', eventCtx.ticketId)
          .single();

      expect(ticket['price'], isA<int>());
      expect(ticket['quantity'], greaterThan(0));
      expect(ticket['sold_count'], isA<int>());

      final remaining =
          (ticket['quantity'] as int) - (ticket['sold_count'] as int);
      expect(remaining, greaterThanOrEqualTo(0));
    });

    testWidgets('결제 금액 포함 신청이 정상 생성된다', (tester) async {
      final client = Supabase.instance.client;

      // Get ticket price for verification
      final ticket = await adminClient
          .from('tickets')
          .select('price')
          .eq('id', eventCtx.ticketId)
          .single();
      final ticketPrice = ticket['price'] as int;

      final appId = await client.rpc<dynamic>(
        'apply_event',
        params: {
          'p_event_id': eventCtx.eventId,
          'p_ticket_id': eventCtx.ticketId,
          'p_user_id': testUserId,
          'p_payment_id': paymentId,
          'p_payment_amount': ticketPrice,
          'p_verification_data': {
            'partner_id': eventCtx.partnerId,
            'verification_id': verificationId,
            'data': {'company': 'E2E Payment Corp', 'position': 'QA'},
          },
        },
      );
      expect(appId, isNotNull);

      // Verify payment_amount is recorded correctly
      final app = await adminClient
          .from('event_applications')
          .select('payment_id, payment_amount, status')
          .eq('id', appId as Object)
          .single();

      expect(app['payment_id'], equals(paymentId));
      expect(app['payment_amount'], equals(ticketPrice));
      expect(app['status'], equals('pending_review'));
    });

    testWidgets('동일 이벤트 중복 신청 시 실패한다', (tester) async {
      final client = Supabase.instance.client;
      final duplicatePaymentId = 'E2E_DUP_${Random().nextInt(99999)}';

      Object? error;
      try {
        await client.rpc<dynamic>(
          'apply_event',
          params: {
            'p_event_id': eventCtx.eventId,
            'p_ticket_id': eventCtx.ticketId,
            'p_user_id': testUserId,
            'p_payment_id': duplicatePaymentId,
            'p_payment_amount': 1000,
            'p_verification_data': {
              'partner_id': eventCtx.partnerId,
              'verification_id': verificationId,
              'data': {'company': 'Duplicate Corp', 'position': 'Dup'},
            },
          },
        );
      } on Object catch (e) {
        error = e;
      }

      expect(
        error,
        isNotNull,
        reason: 'Duplicate application should be rejected',
      );
    });

    testWidgets('신청 후 티켓 sold_count가 증가한다', (tester) async {
      final ticket = await adminClient
          .from('tickets')
          .select('sold_count')
          .eq('id', eventCtx.ticketId)
          .single();

      // sold_count should be at least 1 (from the successful application above)
      expect(
        ticket['sold_count'] as int,
        greaterThanOrEqualTo(1),
        reason: 'sold_count should increment after application',
      );
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
