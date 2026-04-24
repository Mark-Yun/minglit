import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'manual_checkin_controller.g.dart';

/// 이벤트 참가자 목록 + 수동 체크인 처리 컨트롤러.
///
/// - 초기 로드: `get_event_participants_for_checkin` RPC
/// - 체크인 처리: `process_manual_checkin` RPC + optimistic 업데이트
@riverpod
class ManualCheckinController extends _$ManualCheckinController {
  @override
  Future<List<CheckinParticipant>> build(String eventId) async {
    final supabase = ref.watch(supabaseClientProvider);
    return _fetchParticipants(supabase, eventId);
  }

  Future<List<CheckinParticipant>> _fetchParticipants(
    SupabaseClient supabase,
    String eventId,
  ) async {
    final raw = await supabase.rpc<dynamic>(
      'get_event_participants_for_checkin',
      params: {'p_event_id': eventId},
    );
    return (raw as List)
        .cast<Map<String, dynamic>>()
        .map(CheckinParticipant.fromJson)
        .toList();
  }

  /// 수동 체크인 처리.
  ///
  /// 반환값: 'success' | 'already_checked_in' | 'not_found'
  Future<String> checkin(String ticketId) async {
    final supabase = ref.read(supabaseClientProvider);

    // Optimistic 업데이트: 즉시 UI 반영
    final previous = state;
    state = previous.whenData(
      (list) => list.map((p) {
        if (p.ticketId != ticketId) return p;
        return p.copyWith(status: 'checked_in', checkedInAt: DateTime.now());
      }).toList(),
    );

    try {
      final result = await supabase.rpc<dynamic>(
        'process_manual_checkin',
        params: {'p_ticket_id': ticketId, 'p_event_id': eventId},
      ) as String;

      if (result != 'success') {
        // 실패 시 원래 상태 복구
        state = previous;
      }
      return result;
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}
