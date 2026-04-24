import 'dart:async';

import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'checkin_stats_controller.g.dart';

/// 체크인 현황 데이터 모델.
class CheckinStats {
  const CheckinStats({required this.total, required this.checkedIn});

  factory CheckinStats.fromJson(Map<String, dynamic> json) {
    return CheckinStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      checkedIn: (json['checked_in'] as num?)?.toInt() ?? 0,
    );
  }

  final int total;
  final int checkedIn;

  static const empty = CheckinStats(total: 0, checkedIn: 0);
}

/// 이벤트 체크인 현황 컨트롤러.
///
/// - `get_event_checkin_stats` RPC로 초기 데이터 로드
/// - Supabase Realtime `event_participants` 채널 구독으로 실시간 갱신
/// - Realtime 연결 종료 시 30초 폴링으로 폴백
@riverpod
class CheckinStatsController extends _$CheckinStatsController {
  RealtimeChannel? _channel;
  Timer? _pollingTimer;

  @override
  Future<CheckinStats> build(String eventId) async {
    final supabase = ref.watch(supabaseClientProvider);
    final stats = await _fetchStats(supabase, eventId);

    _subscribeToRealtime(supabase, eventId);

    ref.onDispose(() {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      unawaited(_channel?.unsubscribe());
      _channel = null;
    });

    return stats;
  }

  Future<CheckinStats> _fetchStats(
    SupabaseClient supabase,
    String eventId,
  ) async {
    final data = await supabase.rpc<Map<String, dynamic>>(
      'get_event_checkin_stats',
      params: {'p_event_id': eventId},
    );
    return CheckinStats.fromJson(data);
  }

  void _subscribeToRealtime(SupabaseClient supabase, String eventId) {
    _channel = supabase.channel('checkin-stats-$eventId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: eventId,
          ),
          callback: (_) => ref.invalidateSelf(),
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.closed) {
            _startPollingFallback(eventId);
          }
        });
  }

  void _startPollingFallback(String eventId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidateSelf(),
    );
  }
}
