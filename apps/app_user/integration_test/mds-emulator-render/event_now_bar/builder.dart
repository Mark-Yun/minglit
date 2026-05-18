// EventNowBarBuilder — event_now_bar 전용 fluent API.
//
// EventNowBar 는 홈 화면 하단에 부착되는 sub-component. Scaffold bottomSheet
// 으로 마운트하여 실제 사용 환경을 재현한다.
//
// Fix #2588: mds-render-coverage event-operation 카탈로그 등록

import 'dart:async';

import 'package:app_user/src/features/home/widgets/event_now_bar.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

// ---------------------------------------------------------------------------
// Fake notifiers — no Supabase / network in render context
// ---------------------------------------------------------------------------

class _FixedStateNotifier extends EventNowBarStateNotifier {
  _FixedStateNotifier(this._state);
  final EventNowBarState _state;

  @override
  FutureOr<EventNowBarState> build(TodayActiveEvent activeEvent) => _state;
}

class _NoOpRealtime extends EventRealtime {
  @override
  void build(String eventId) {}
}

// ---------------------------------------------------------------------------
// Builder
// ---------------------------------------------------------------------------

TodayActiveEvent _makeActiveEvent({
  String participantStatus = 'ticket_issued',
}) {
  final base = DateTime(2026, 5, 18, 18);
  return TodayActiveEvent(
    event: Event(
      id: 'render-event-1',
      partyId: 'render-party-1',
      title: '강남 밍릿파티',
      startTime: base,
      endTime: base.add(const Duration(hours: 2)),
      createdAt: base,
      updatedAt: base,
    ),
    participantStatus: participantStatus,
  );
}

class EventNowBarBuilder extends MdsScreenBuilder<Scaffold> {
  EventNowBarBuilder()
    : super(
        page: const Scaffold(
          body: SizedBox.expand(),
          bottomSheet: EventNowBar(),
        ),
        base: [],
      );

  void _applyState(EventNowBarState state) {
    final activeEvent = _makeActiveEvent(
      participantStatus:
          state == EventNowBarState.checkedIn ? 'checked_in' : 'ticket_issued',
    );
    addOverride(
      todayActiveEventsProvider.overrideWith((ref) async => [activeEvent]),
    );
    addOverride(
      eventNowBarStateProvider(
        activeEvent,
      ).overrideWith(() => _FixedStateNotifier(state)),
    );
    addOverride(
      eventRealtimeProvider(activeEvent.event.id).overrideWith(
        _NoOpRealtime.new,
      ),
    );
  }

  /// CUJ 1-1: 이벤트 시작 전 대기 상태 (곧 시작).
  void waiting() => _applyState(EventNowBarState.waiting);

  /// CUJ 1-2: 입장 가능 상태 (체크인하세요).
  void checkInReady() => _applyState(EventNowBarState.checkInReady);

  /// 체크인 완료 상태.
  void checkedIn() => _applyState(EventNowBarState.checkedIn);

  /// 오프라인 / 에러 상태 — provider 오류 시 fallback bar.
  void offline() {
    addOverride(
      todayActiveEventsProvider
          .overrideWith((ref) => throw Exception('offline')),
    );
  }

  /// 다크 모드 토글.
  void dark() => useDarkTheme();
}
