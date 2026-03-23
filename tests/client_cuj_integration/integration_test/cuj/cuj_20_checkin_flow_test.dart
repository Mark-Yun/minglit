import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 20: Check-in Flow
/// — approved participant gets ticket, checks in via Edge Function,
///   re-check-in returns 409 conflict.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext eventCtx;
  late String testUserId;
  late String testEmail;
  late String verificationId;
  String? applicationId;
  String? participantId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    eventCtx = await findScheduledEvent(adminClient);

    testEmail = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(testEmail);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
    verificationId = await getCareerVerificationId(adminClient);

    await _cleanup(adminClient, testUserId, eventCtx.eventId);

    // Create application, approve, and get participant with ticket
    applicationId = await Supabase.instance.client.rpc<dynamic>(
      'apply_event',
      params: {
        'p_event_id': eventCtx.eventId,
        'p_ticket_id': eventCtx.ticketId,
        'p_user_id': testUserId,
        'p_payment_id': 'E2E_CHK_${Random().nextInt(99999)}',
        'p_payment_amount': 1000,
        'p_verification_data': {
          'partner_id': eventCtx.partnerId,
          'verification_id': verificationId,
          'data': {
            'company': 'Checkin Test Corp',
            'position': 'QA',
          },
        },
      },
    ) as String;

    // Approve verification → triggers approved + participant creation
    await adminClient
        .from('verification_submissions')
        .update({'status': 'approved'}).eq('application_id', applicationId!);

    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Set application to paid (required for participant ticket_issued)
    await adminClient.from('event_applications').update({
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
    }).eq('id', applicationId!);

    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Get participant record
    final participant = await retry(() async {
      final res = await adminClient
          .from('event_participants')
          .select()
          .eq('application_id', applicationId!)
          .maybeSingle();
      if (res == null) throw Exception('Participant not yet created');
      return res;
    });
    participantId = participant['id'] as String;

    // Ensure participant is in ticket_issued status
    await adminClient
        .from('event_participants')
        .update({'status': 'ticket_issued'}).eq('id', participantId!);
  });

  tearDownAll(() async {
    await _cleanup(adminClient, testUserId, eventCtx.eventId);
    await signOut();
  });

  group('CUJ 20: Check-in Flow', () {
    testWidgets('approved participant의 ticket_code를 조회할 수 있다', (tester) async {
      final participant = await adminClient
          .from('event_participants')
          .select('ticket_code, status')
          .eq('id', participantId!)
          .single();

      expect(
        participant['ticket_code'],
        isNotNull,
        reason: 'Approved participant should have a ticket_code',
      );
      expect(participant['status'], equals('ticket_issued'));
    });

    testWidgets('체크인 처리 후 checked_in 상태로 변경된다', (tester) async {
      final client = Supabase.instance.client;

      final response = await client.functions.invoke(
        'event-checkin',
        body: {
          'event_id': eventCtx.eventId,
          'participant_id': participantId,
        },
      );

      expect(
        response.status,
        equals(200),
        reason: 'Check-in should succeed: ${response.data}',
      );

      final body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['status'], equals('checked_in'));

      // Verify in DB
      final participant = await adminClient
          .from('event_participants')
          .select('status')
          .eq('id', participantId!)
          .single();
      expect(participant['status'], equals('checked_in'));
    });

    testWidgets('이미 체크인한 참가자 재체크인 시도 시 409 에러가 발생한다', (tester) async {
      final client = Supabase.instance.client;

      final response = await client.functions.invoke(
        'event-checkin',
        body: {
          'event_id': eventCtx.eventId,
          'participant_id': participantId,
        },
      );

      expect(
        response.status,
        equals(409),
        reason: 'Re-check-in should return 409 Conflict',
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
