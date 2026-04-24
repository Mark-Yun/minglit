import 'dart:async';

import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

/// PostgrestFilterBuilder를 구현하는 fake. rpc() 스텁 반환값으로 사용.
class _FakeRpcBuilder<T> implements PostgrestFilterBuilder<T> {
  _FakeRpcBuilder(this._data);
  final T _data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_data).then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}

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
      ),
    ).thenAnswer((_) => _FakeRpcBuilder<dynamic>(response));
  }

  void stubCheckin(String result) {
    when(
      () => mockClient.rpc<dynamic>(
        'process_manual_checkin',
        params: any(named: 'params'),
      ),
    ).thenAnswer((_) => _FakeRpcBuilder<dynamic>(result));
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

    test('checkin — not_found: optimistic 업데이트 롤백', () async {
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
      stubCheckin('not_found');

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(manualCheckinControllerProvider('event-1').future);

      final result = await container
          .read(manualCheckinControllerProvider('event-1').notifier)
          .checkin('tk-1');

      expect(result, 'not_found');

      // Fix #1812: not_found이면 티켓이 존재하지 않으므로 optimistic 상태를 이전으로 복구
      final state = container.read(manualCheckinControllerProvider('event-1'));
      expect(state.value!.first.isCheckedIn, isFalse);
    });

    test('checkin — already_checked_in: optimistic 상태 유지 (서버도 checked_in)', () async {
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

      // Fix #1812: already_checked_in은 서버 실제 상태도 checked_in이므로
      // optimistic 상태(checked_in)를 유지해야 한다.
      final state = container.read(manualCheckinControllerProvider('event-1'));
      expect(state.value!.first.isCheckedIn, isTrue);
    });
  });
}
