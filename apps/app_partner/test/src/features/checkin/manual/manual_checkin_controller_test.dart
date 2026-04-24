import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late _MockSupabaseClient mockClient;

  setUp(() {
    mockClient = _MockSupabaseClient();
  });

  void stubFetch(List<dynamic> response) {
    when(
      () => mockClient.rpc<dynamic>(
            'get_event_participants_for_checkin',
            params: any(named: 'params'),
          ) as Future<dynamic>,
    ).thenAnswer((_) async => response);
  }

  void stubCheckin(String result) {
    when(
      () => mockClient.rpc<dynamic>(
            'process_manual_checkin',
            params: any(named: 'params'),
          ) as Future<dynamic>,
    ).thenAnswer((_) async => result);
  }

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(mockClient)],
    );
  }

  group('ManualCheckinController', () {
    test('RPC 호출 후 참가자 목록 파싱', () async {
      stubFetch([
        {
          'id': 'ep-1',
          'ticket_id': 'tk-1',
          'name': '김민지',
          'phone_last4': '1234',
          'status': 'ticket_issued',
          'checked_in_at': null,
        },
        {
          'id': 'ep-2',
          'ticket_id': 'tk-2',
          'name': '박재훈',
          'phone_last4': '5678',
          'status': 'checked_in',
          'checked_in_at': '2026-04-24T09:00:00Z',
        },
      ]);

      final container = makeContainer();
      addTearDown(container.dispose);

      final participants = await container.read(
        manualCheckinControllerProvider('event-1').future,
      );

      expect(participants, hasLength(2));
      expect(participants[0].name, '김민지');
      expect(participants[0].isCheckedIn, isFalse);
      expect(participants[1].name, '박재훈');
      expect(participants[1].isCheckedIn, isTrue);
    });

    test('빈 참가자 목록', () async {
      stubFetch([]);

      final container = makeContainer();
      addTearDown(container.dispose);

      final participants = await container.read(
        manualCheckinControllerProvider('event-empty').future,
      );

      expect(participants, isEmpty);
    });

    test('checkin — success: optimistic 업데이트 후 유지', () async {
      stubFetch([
        {
          'id': 'ep-1',
          'ticket_id': 'tk-1',
          'name': '김민지',
          'phone_last4': '1234',
          'status': 'ticket_issued',
          'checked_in_at': null,
        },
      ]);
      stubCheckin('success');

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(manualCheckinControllerProvider('event-1').future);

      final result = await container
          .read(manualCheckinControllerProvider('event-1').notifier)
          .checkin('tk-1');

      expect(result, 'success');

      final updated = container.read(manualCheckinControllerProvider('event-1'));
      final participant = updated.value!.first;
      expect(participant.isCheckedIn, isTrue);
    });

    test('checkin — already_checked_in: 상태 복구', () async {
      stubFetch([
        {
          'id': 'ep-1',
          'ticket_id': 'tk-1',
          'name': '김민지',
          'phone_last4': '1234',
          'status': 'ticket_issued',
          'checked_in_at': null,
        },
      ]);
      stubCheckin('already_checked_in');

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(manualCheckinControllerProvider('event-1').future);

      final result = await container
          .read(manualCheckinControllerProvider('event-1').notifier)
          .checkin('tk-1');

      expect(result, 'already_checked_in');

      // 실패 시 원래 상태로 복구
      final state = container.read(manualCheckinControllerProvider('event-1'));
      expect(state.value!.first.isCheckedIn, isFalse);
    });
  });
}
