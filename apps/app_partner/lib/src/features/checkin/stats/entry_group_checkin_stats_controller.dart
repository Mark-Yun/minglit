import 'dart:async';

import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'entry_group_checkin_stats_controller.g.dart';

/// 엔트리 그룹별 체크인 현황 데이터 모델.
class EntryGroupCheckinStats {
  const EntryGroupCheckinStats({
    required this.id,
    required this.label,
    required this.total,
    required this.checkedIn,
  });

  factory EntryGroupCheckinStats.fromJson(Map<String, dynamic> json) {
    return EntryGroupCheckinStats(
      id: json['id'] as String,
      label: json['label'] as String,
      total: (json['total'] as num).toInt(),
      checkedIn: (json['checked_in'] as num).toInt(),
    );
  }

  final String id;
  final String label;
  final int total;
  final int checkedIn;

  double get ratio => total == 0 ? 0.0 : checkedIn / total;
}

/// 이벤트의 엔트리 그룹별 체크인 현황 컨트롤러.
///
/// - `get_event_checkin_stats_by_group` RPC로 초기 데이터 로드
/// - Supabase Realtime `event_participants` 채널 구독으로 실시간 갱신
@riverpod
class EntryGroupCheckinStatsController
    extends _$EntryGroupCheckinStatsController {
  RealtimeChannel? _channel;

  @override
  Future<List<EntryGroupCheckinStats>> build(String eventId) async {
    final supabase = ref.watch(supabaseClientProvider);
    final groups = await _fetchGroupStats(supabase, eventId);

    _subscribeToRealtime(supabase, eventId);

    ref.onDispose(() {
      unawaited(_channel?.unsubscribe());
      _channel = null;
    });

    return groups;
  }

  Future<List<EntryGroupCheckinStats>> _fetchGroupStats(
    SupabaseClient supabase,
    String eventId,
  ) async {
    final raw = await supabase.rpc<dynamic>(
      'get_event_checkin_stats_by_group',
      params: {'p_event_id': eventId},
    );
    return (raw as List)
        .cast<Map<String, dynamic>>()
        .map(EntryGroupCheckinStats.fromJson)
        .toList();
  }

  void _subscribeToRealtime(SupabaseClient supabase, String eventId) {
    _channel = supabase.channel('checkin-group-stats-$eventId');
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
        .subscribe();
  }
}
