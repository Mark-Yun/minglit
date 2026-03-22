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
  String? applicationId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    eventCtx = await findScheduledEvent(adminClient);
    final email = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(email);
    testUserId = Supabase.instance.client.auth.currentUser!.id;

    // Cleanup any leftover data
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
  });

  tearDownAll(() async {
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
    await signOut();
  });

  group('CUJ 03: Application', () {
    testWidgets('이벤트에 신청하면 pending_review 상태로 생성된다',
        (tester) async {
      final client = Supabase.instance.client;
      final verificationId = await getCareerVerificationId(adminClient);

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
      applicationId = appId as String;

      final app = await client
          .from('event_applications')
          .select()
          .eq('id', appId as Object)
          .single();
      expect(app['status'], equals('pending_review'));
    });

    testWidgets('관리자가 심사 승인하면 approved 상태가 된다',
        (tester) async {
      expect(applicationId, isNotNull,
          reason: 'Previous test must create application',);

      await adminClient
          .from('verification_submissions')
          .update({'status': 'approved'}).eq(
              'application_id', applicationId!,);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      final updatedApp = await adminClient
          .from('event_applications')
          .select()
          .eq('id', applicationId!)
          .single();
      expect(updatedApp['status'], equals('approved'));
    });

    testWidgets('승인 후 participant가 생성된다', (tester) async {
      expect(applicationId, isNotNull,
          reason: 'Previous test must create application',);

      final participant = await adminClient
          .from('event_participants')
          .select()
          .eq('application_id', applicationId!)
          .maybeSingle();
      expect(participant, isNotNull, reason: 'Participant should be created');
      expect(participant!['ticket_code'], isNotNull);
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
