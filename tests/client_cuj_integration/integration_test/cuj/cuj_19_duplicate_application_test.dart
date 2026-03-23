import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 19: Duplicate Application Prevention
/// — Same user applying to same event twice should fail with a clear error.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String testUserId;
  late String verificationId;
  String? firstApplicationId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    eventCtx = await findScheduledEvent(adminClient);

    final email = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(email);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
    verificationId = await getCareerVerificationId(adminClient);

    await _cleanup(adminClient, testUserId, eventCtx.eventId);
  });

  tearDownAll(() async {
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
    await signOut();
  });

  group('CUJ 19: Duplicate Application Prevention', () {
    testWidgets('첫 번째 신청은 성공한다', (tester) async {
      final client = Supabase.instance.client;

      final appId = await client.rpc<dynamic>(
        'apply_event',
        params: {
          'p_event_id': eventCtx.eventId,
          'p_ticket_id': eventCtx.ticketId,
          'p_user_id': testUserId,
          'p_payment_id': 'E2E_DUP1_${Random().nextInt(99999)}',
          'p_payment_amount': 1000,
          'p_verification_data': {
            'partner_id': eventCtx.partnerId,
            'verification_id': verificationId,
            'data': {'company': 'Dup Test Corp', 'position': 'Tester'},
          },
        },
      );

      expect(appId, isNotNull, reason: 'First application should succeed');
      firstApplicationId = appId as String;
    });

    testWidgets('동일 유저가 동일 이벤트에 2회 신청하면 에러가 발생한다', (tester) async {
      expect(
        firstApplicationId,
        isNotNull,
        reason: 'Previous test must create first application',
      );

      final client = Supabase.instance.client;

      try {
        await client.rpc<dynamic>(
          'apply_event',
          params: {
            'p_event_id': eventCtx.eventId,
            'p_ticket_id': eventCtx.ticketId,
            'p_user_id': testUserId,
            'p_payment_id': 'E2E_DUP2_${Random().nextInt(99999)}',
            'p_payment_amount': 1000,
            'p_verification_data': {
              'partner_id': eventCtx.partnerId,
              'verification_id': verificationId,
              'data': {'company': 'Dup Test Corp', 'position': 'Tester'},
            },
          },
        );
        fail('Second application should fail due to unique constraint');
      } on PostgrestException catch (e) {
        // unique(event_id, user_id) violation — code 23505
        expect(
          e.message,
          isNotEmpty,
          reason: 'Error message should indicate duplicate',
        );
      }
    });

    testWidgets('에러 메시지가 PostgrestException 구조를 갖는다', (tester) async {
      expect(
        firstApplicationId,
        isNotNull,
        reason: 'Previous test must create first application',
      );

      final client = Supabase.instance.client;

      PostgrestException? caughtError;
      try {
        await client.rpc<dynamic>(
          'apply_event',
          params: {
            'p_event_id': eventCtx.eventId,
            'p_ticket_id': eventCtx.ticketId,
            'p_user_id': testUserId,
            'p_payment_id': 'E2E_DUP3_${Random().nextInt(99999)}',
            'p_payment_amount': 1000,
          },
        );
      } on PostgrestException catch (e) {
        caughtError = e;
      }

      expect(
        caughtError,
        isNotNull,
        reason: 'Duplicate application should throw PostgrestException',
      );
      expect(caughtError!.code, isNotNull);
      expect(caughtError.message, isNotEmpty);
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
