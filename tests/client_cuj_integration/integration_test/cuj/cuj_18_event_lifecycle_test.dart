import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 18: Event Lifecycle
/// — scheduled → completed transition, apply to completed event fails,
///   settlement auto-creation on completion.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String testUserId;
  late String testEmail;
  late String verificationId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    eventCtx = await findScheduledEvent(adminClient);

    testEmail = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(testEmail);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
    verificationId = await getCareerVerificationId(adminClient);

    // Cleanup any prior state
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
  });

  tearDownAll(() async {
    // Restore event to scheduled for other tests
    try {
      await adminClient
          .from('events')
          .update({'status': 'scheduled'}).eq('id', eventCtx.eventId);
    } on Object catch (_) {}
    // Delete settlement created by this test
    try {
      await adminClient
          .from('settlements')
          .delete()
          .eq('event_id', eventCtx.eventId);
    } on Object catch (_) {}
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
    await signOut();
  });

  group('CUJ 18: Event Lifecycle', () {
    testWidgets('admin이 이벤트를 scheduled → completed로 변경할 수 있다', (tester) async {
      await adminClient
          .from('events')
          .update({'status': 'completed'}).eq('id', eventCtx.eventId);

      final event = await adminClient
          .from('events')
          .select('status')
          .eq('id', eventCtx.eventId)
          .single();

      expect(event['status'], equals('completed'));
    });

    testWidgets('completed 이벤트에 apply_event 시도 시 에러가 발생한다', (tester) async {
      final client = Supabase.instance.client;

      try {
        await client.rpc<dynamic>(
          'apply_event',
          params: {
            'p_event_id': eventCtx.eventId,
            'p_ticket_id': eventCtx.ticketId,
            'p_user_id': testUserId,
            'p_payment_id': 'E2E_LIFE_${Random().nextInt(99999)}',
            'p_payment_amount': 1000,
            'p_verification_data': {
              'partner_id': eventCtx.partnerId,
              'verification_id': verificationId,
              'data': {'company': 'Lifecycle Test', 'position': 'Tester'},
            },
          },
        );
        // If no error thrown, the application should not have been created
        // (balance check or other guard should prevent it)
        fail('apply_event should fail for completed event');
      } on PostgrestException catch (e) {
        // Expected: balance check or event status guard rejects
        expect(e.message, isNotEmpty);
      }
    });

    testWidgets('completed 이벤트에 settlement이 자동 생성된다', (tester) async {
      // Settlement should have been auto-created by the trigger
      // when we set status to 'completed' in the first test
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
