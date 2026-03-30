import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 08: Partner Event Creation
/// — Create event, add ticket, publish, verify user visibility.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late ScheduledEventContext seedCtx;
  String? createdEventId;
  String? createdTicketId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    seedCtx = await findScheduledEvent(adminClient);

    final ownerEmail = await getPartnerOwnerEmail(
      adminClient,
      ownerId: seedCtx.ownerId,
    );
    await signInAsTestUser(ownerEmail);
  });

  tearDownAll(() async {
    // Cleanup created test data
    if (createdTicketId != null) {
      try {
        await adminClient
            .from('tickets')
            .delete()
            .eq('id', createdTicketId!);
      } on Object catch (_) {}
    }
    if (createdEventId != null) {
      try {
        await adminClient
            .from('events')
            .delete()
            .eq('id', createdEventId!);
      } on Object catch (_) {}
    }
    await signOut();
  });

  group('CUJ 08: Partner Event Creation', () {
    testWidgets('파트너 owner가 이벤트를 생성할 수 있다',
        (tester) async {
      final client = Supabase.instance.client;
      final now = DateTime.now();
      final startTime =
          now.add(const Duration(days: 7)).toIso8601String();
      final endTime =
          now.add(const Duration(days: 7, hours: 3)).toIso8601String();

      final res = await client.from('events').insert({
        'party_id': seedCtx.partyId,
        'title': 'E2E 테스트 이벤트 ${now.millisecondsSinceEpoch}',
        'description': {'text': 'E2E 자동 생성 이벤트'},
        'start_time': startTime,
        'end_time': endTime,
        'max_participants': 10,
        'status': 'scheduled',
      }).select('id').single();

      createdEventId = res['id'] as String;
      expect(createdEventId, isNotNull);
    });

    testWidgets('생성된 이벤트에 티켓을 추가할 수 있다',
        (tester) async {
      expect(
        createdEventId,
        isNotNull,
        reason: 'Previous test must create event',
      );

      final client = Supabase.instance.client;

      final res = await client.from('tickets').insert({
        'event_id': createdEventId,
        'name': 'E2E 일반 티켓',
        'price': 15000,
        'quantity': 10,
      }).select('id').single();

      createdTicketId = res['id'] as String;
      expect(createdTicketId, isNotNull);
    });

    testWidgets('이벤트 상태가 scheduled인지 확인한다',
        (tester) async {
      expect(
        createdEventId,
        isNotNull,
        reason: 'Previous test must create event',
      );

      final event = await adminClient
          .from('events')
          .select('status')
          .eq('id', createdEventId!)
          .single();

      expect(event['status'], equals('scheduled'));
    });

    testWidgets(
      '일반 유저가 생성된 이벤트를 조회할 수 있다',
      (tester) async {
        expect(
          createdEventId,
          isNotNull,
          reason: 'Previous test must create event',
        );

        // Switch to a regular user
        await signOut();
        final userEmail = await _getRegularUserEmail(adminClient);
        await signInAsTestUser(userEmail);

        final client = Supabase.instance.client;
        final event = await client
            .from('events')
            .select('id, title, status')
            .eq('id', createdEventId!)
            .maybeSingle();

        expect(event, isNotNull, reason: 'User should see the event');
        expect(event!['status'], equals('scheduled'));

        // Sign back as partner owner for teardown
        await signOut();
        final ownerEmail = await getPartnerOwnerEmail(
          adminClient,
          ownerId: seedCtx.ownerId,
        );
        await signInAsTestUser(ownerEmail);
      },
    );
  });
}

/// Gets a regular (non-partner) test user email.
Future<String> _getRegularUserEmail(
  SupabaseClient adminClient,
) async {
  final targetBirthYear = DateTime.now().year - 25 + 1;

  final res = await adminClient
      .from('user_profiles')
      .select('id')
      .eq('gender', 'male')
      .eq('birth_date', '$targetBirthYear-01-01')
      .like('username', '%_ok')
      .limit(1)
      .single();

  final userId = res['id'] as String;
  final userResponse =
      await adminClient.auth.admin.getUserById(userId);

  return userResponse.user!.email!;
}
