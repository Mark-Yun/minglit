import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 09: Partner Verification Review
/// — Partner owner reviews applications: approve + reject.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext seedCtx;
  late String testUserId;
  late String testUserEmail;
  late String ownerEmail;
  String? applicationId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    seedCtx = await findScheduledEvent(adminClient);

    ownerEmail = await getPartnerOwnerEmail(
      adminClient,
      ownerId: seedCtx.ownerId,
    );

    // Create a test application as a regular user
    testUserEmail = await _getTestUserEmail(adminClient);
    await signInAsTestUser(testUserEmail);
    testUserId =
        Supabase.instance.client.auth.currentUser!.id;
    await signOut();

    // Cleanup any leftover data
    await _cleanup(
      adminClient,
      testUserId,
      seedCtx.eventId,
    );
  });

  tearDownAll(() async {
    await _cleanup(
      adminClient,
      testUserId,
      seedCtx.eventId,
    );
    await signOut();
  });

  group('CUJ 09: Partner Review', () {
    testWidgets('유저가 이벤트에 신청한다 (심사 준비)',
        (tester) async {
      await signInAsTestUser(testUserEmail);
      final client = Supabase.instance.client;

      final verificationId = await _getVerificationId(adminClient);

      final appId = await client.rpc<dynamic>(
        'apply_event',
        params: {
          'p_event_id': seedCtx.eventId,
          'p_ticket_id': seedCtx.ticketId,
          'p_user_id': testUserId,
          'p_payment_id': 'E2E_REV_${Random().nextInt(99999)}',
          'p_payment_amount': 1000,
          'p_verification_data': {
            'partner_id': seedCtx.partnerId,
            'verification_id': verificationId,
            'data': {
              'company': 'Review Test Corp',
              'position': 'Engineer',
            },
          },
        },
      );
      applicationId = appId as String;
      expect(applicationId, isNotNull);

      await signOut();
    });

    testWidgets(
      '파트너 owner가 신청 목록을 조회할 수 있다',
      (tester) async {
        expect(
          applicationId,
          isNotNull,
          reason: 'Previous test must create application',
        );

        await signInAsTestUser(ownerEmail);
        final client = Supabase.instance.client;

        final apps = await client
            .from('event_applications')
            .select('id, status, user_id')
            .eq('event_id', seedCtx.eventId) as List;

        expect(apps, isNotEmpty);

        final targetApp = apps.where(
          (a) =>
              (a as Map<String, dynamic>)['id'] ==
              applicationId,
        );
        expect(
          targetApp,
          isNotEmpty,
          reason: 'Owner should see the application',
        );

        await signOut();
      },
    );

    testWidgets(
      '파트너 owner가 심사를 승인하면 approved 상태가 된다',
      (tester) async {
        expect(
          applicationId,
          isNotNull,
          reason: 'Previous test must create application',
        );

        // Approve via admin (simulates partner action)
        await adminClient
            .from('verification_submissions')
            .update({'status': 'approved'}).eq(
          'application_id',
          applicationId!,
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );

        final app = await adminClient
            .from('event_applications')
            .select('status')
            .eq('id', applicationId!)
            .single();

        expect(app['status'], equals('approved'));
      },
    );

    testWidgets('승인 후 participant가 생성된다', (tester) async {
      expect(
        applicationId,
        isNotNull,
        reason: 'Previous test must create application',
      );

      final participant = await adminClient
          .from('event_participants')
          .select('id, ticket_code')
          .eq('application_id', applicationId!)
          .maybeSingle();

      expect(
        participant,
        isNotNull,
        reason: 'Participant should be created on approval',
      );
      expect(participant!['ticket_code'], isNotNull);
    });
  });
}

Future<String> _getTestUserEmail(
  SupabaseClient adminClient,
) async {
  final targetBirthYear = DateTime.now().year - 25 + 1;

  final res = await adminClient
      .from('user_profiles')
      .select('id')
      .eq('gender', 'female')
      .eq('birth_date', '$targetBirthYear-01-01')
      .like('username', '%_ok')
      .limit(1)
      .single();

  final userId = res['id'] as String;
  final userResponse =
      await adminClient.auth.admin.getUserById(userId);
  return userResponse.user!.email!;
}

Future<String> _getVerificationId(
  SupabaseClient client,
) async {
  final res = await client
      .from('verifications')
      .select('id')
      .eq('category', 'career')
      .limit(1)
      .maybeSingle();

  if (res == null) {
    final any = await client
        .from('verifications')
        .select('id')
        .limit(1)
        .single();
    return any['id'] as String;
  }
  return res['id'] as String;
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
      await admin
          .from('event_applications')
          .delete()
          .eq('id', appId);
    }
  } on Object catch (_) {}
}
