import 'dart:async';

import 'package:app_partner/src/features/checkin/stats/entry_group_checkin_stats_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockRealtimeChannel extends Mock implements RealtimeChannel {}

/// Fix #1817: rpc()는 PostgrestFilterBuilder<T>를 반환하므로 Future로 직접 stub 불가.
class _FakeRpcBuilder<T> implements PostgrestFilterBuilder<T> {
  _FakeRpcBuilder(this._data);
  final T _data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T) onValue, {
    Function? onError,
  }) => Future<T>.value(_data).then(onValue, onError: onError);

  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}

void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(
      PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'event_id',
        value: 'fallback',
      ),
    );
  });

  late _MockSupabaseClient mockClient;
  late _MockRealtimeChannel mockChannel;

  setUp(() {
    mockClient = _MockSupabaseClient();
    mockChannel = _MockRealtimeChannel();

    when(() => mockClient.channel(any())).thenReturn(mockChannel);

    when(
      () => mockChannel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        filter: any(named: 'filter'),
        callback: any(named: 'callback'),
      ),
    ).thenReturn(mockChannel);

    when(() => mockChannel.subscribe()).thenReturn(mockChannel);
    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
  });

  void stubRpc(List<dynamic> response) {
    when(
      () => mockClient.rpc<dynamic>(
        'get_event_checkin_stats_by_group',
        params: any(named: 'params'),
      ),
    ).thenAnswer((_) => _FakeRpcBuilder<dynamic>(response));
  }

  ProviderContainer makeContainer({required List<dynamic> groupsResponse}) {
    stubRpc(groupsResponse);
    return ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(mockClient)],
    );
  }

  group('EntryGroupCheckinStatsController', () {
    test('RPC 호출 후 그룹 데이터 파싱', () async {
      final container = makeContainer(
        groupsResponse: [
          {
            'id': 'group-1',
            'label': '남 20대 초반',
            'total': 14,
            'checked_in': 13,
          },
          {
            'id': 'group-2',
            'label': '여 20대 초반',
            'total': 14,
            'checked_in': 5,
          },
        ],
      );
      addTearDown(container.dispose);

      final groups = await container.read(
        entryGroupCheckinStatsControllerProvider('event-1').future,
      );

      expect(groups.length, 2);
      expect(groups[0].label, '남 20대 초반');
      expect(groups[0].total, 14);
      expect(groups[0].checkedIn, 13);
      expect(groups[1].label, '여 20대 초반');
      expect(groups[1].checkedIn, 5);
    });

    test('빈 배열 반환 — 엔트리 그룹 없는 이벤트', () async {
      final container = makeContainer(groupsResponse: []);
      addTearDown(container.dispose);

      final groups = await container.read(
        entryGroupCheckinStatsControllerProvider('event-empty').future,
      );

      expect(groups, isEmpty);
    });

    test('ratio 계산: total=0이면 0.0', () {
      const stats = EntryGroupCheckinStats(
        id: 'g',
        label: 'test',
        total: 0,
        checkedIn: 0,
      );
      expect(stats.ratio, 0.0);
    });

    test('ratio 계산: 13/14 ≈ 0.928', () {
      const stats = EntryGroupCheckinStats(
        id: 'g',
        label: 'test',
        total: 14,
        checkedIn: 13,
      );
      expect(stats.ratio, closeTo(0.928, 0.001));
    });

    test('Realtime 구독 시 올바른 채널명 사용', () async {
      final container = makeContainer(groupsResponse: []);
      addTearDown(container.dispose);

      await container.read(
        entryGroupCheckinStatsControllerProvider('event-rt').future,
      );

      verify(
        () => mockClient.channel('checkin-group-stats-event-rt'),
      ).called(1);
    });

    test('dispose 시 채널 unsubscribe', () async {
      final container = makeContainer(groupsResponse: []);

      await container.read(
        entryGroupCheckinStatsControllerProvider('event-disp').future,
      );

      container.dispose();

      verify(() => mockChannel.unsubscribe()).called(1);
    });
  });
}
