import 'package:app_partner/src/features/checkin/stats/checkin_stats_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  late _MockSupabaseClient mockClient;
  late _MockRealtimeChannel mockChannel;

  setUp(() {
    mockClient = _MockSupabaseClient();
    mockChannel = _MockRealtimeChannel();

    // channel() 호출 시 mock 채널 반환
    when(() => mockClient.channel(any())).thenReturn(mockChannel);

    // Realtime chain stub — subscribe callback으로 즉시 subscribed 반환
    when(
      () => mockChannel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        filter: any(named: 'filter'),
        callback: any(named: 'callback'),
      ),
    ).thenReturn(mockChannel);

    when(
      () => mockChannel.subscribe(
        any(),
      ),
    ).thenReturn(mockChannel);

    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
  });

  ProviderContainer makeContainer({
    required Map<String, dynamic> statsResponse,
  }) {
    when(
      () =>
          mockClient.rpc<dynamic>(
                'get_event_checkin_stats',
                params: any(named: 'params'),
              )
              as Future<dynamic>,
    ).thenAnswer((_) async => statsResponse);

    return ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockClient),
      ],
    );
  }

  group('CheckinStatsController', () {
    test('초기 stats RPC 호출 후 데이터 반환', () async {
      final container = makeContainer(
        statsResponse: {'total': 50, 'checked_in': 23},
      );
      addTearDown(container.dispose);

      final asyncValue = await container.read(
        checkinStatsControllerProvider('event-1').future,
      );

      expect(asyncValue.total, 50);
      expect(asyncValue.checkedIn, 23);
      verify(
        () => mockClient.rpc<dynamic>(
          'get_event_checkin_stats',
          params: {'p_event_id': 'event-1'},
        ),
      ).called(1);
    });

    test('total=0 이벤트 — 0/0 반환', () async {
      final container = makeContainer(
        statsResponse: {'total': 0, 'checked_in': 0},
      );
      addTearDown(container.dispose);

      final asyncValue = await container.read(
        checkinStatsControllerProvider('event-empty').future,
      );

      expect(asyncValue.total, 0);
      expect(asyncValue.checkedIn, 0);
    });

    test('Realtime 구독 시 event_participants 채널 생성', () async {
      final container = makeContainer(
        statsResponse: {'total': 10, 'checked_in': 5},
      );
      addTearDown(container.dispose);

      await container.read(
        checkinStatsControllerProvider('event-rt').future,
      );

      verify(() => mockClient.channel('checkin-stats-event-rt')).called(1);
      verify(
        () => mockChannel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_participants',
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        ),
      ).called(1);
    });

    test('dispose 시 채널 unsubscribe', () async {
      final container = makeContainer(
        statsResponse: {'total': 5, 'checked_in': 2},
      );

      await container.read(
        checkinStatsControllerProvider('event-disp').future,
      );

      container.dispose();

      verify(() => mockChannel.unsubscribe()).called(1);
    });
  });
}
