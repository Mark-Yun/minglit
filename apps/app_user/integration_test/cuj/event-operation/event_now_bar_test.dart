// CUJ tests — event-operation / event-now-bar (app_user)
//
// 대응 spec: docs/features/event-operation/event-now-bar/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// Fix #2564: event-operation 카테고리 CUJ integration test 전무 해소 (event-now-bar)

import 'dart:async';

import 'package:app_user/src/features/home/widgets/event_now_bar.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Fake providers for isolation (no Supabase/network in test)
// ---------------------------------------------------------------------------

class _FakeEventNowBarStateNotifier extends EventNowBarStateNotifier {
  _FakeEventNowBarStateNotifier(this._state);

  final EventNowBarState _state;

  @override
  FutureOr<EventNowBarState> build(TodayActiveEvent activeEvent) => _state;
}

class _FakeEventRealtime extends EventRealtime {
  @override
  void build(String eventId) {} // no-op: no Supabase subscription in tests
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Event _makeEvent({String id = 'evt-1'}) => Event(
  id: id,
  partyId: 'party-1',
  title: 'Test Event',
  startTime: DateTime(2026, 5, 18, 18),
  endTime: DateTime(2026, 5, 18, 20),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

TodayActiveEvent _makeActiveEvent() => TodayActiveEvent(
  event: _makeEvent(),
  participantStatus: 'ticket_issued',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 이벤트 시작 3시간 전 미니바 자동 노출 (FR-1)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '오늘 활성 이벤트 시 미니바 노출', () {
    cujCase(
      'happy: 활성 이벤트 있을 때 → 상태 레이블 표시 (곧 시작)',
      app: const Scaffold(body: EventNowBar()),
      overrides: () {
        final activeEvent = _makeActiveEvent();
        return [
          todayActiveEventsProvider.overrideWith(
            (ref) async => [activeEvent],
          ),
          eventNowBarStateProvider(activeEvent).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.waiting),
          ),
          eventRealtimeProvider(activeEvent.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('곧 시작'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 오늘 활성 이벤트 없을 때 → 미니바 숨김',
      app: const Scaffold(body: EventNowBar()),
      overrides: () => [
        todayActiveEventsProvider.overrideWith((ref) async => []),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 이벤트 없으면 SizedBox.shrink — 상태 레이블 없음
        expect(find.text('곧 시작'), findsNothing);
        expect(find.text('체크인하세요'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: Realtime 끊김 시 폴링 fallback (FR-12) — 오프라인 상태 렌더
  // ---------------------------------------------------------------------------

  cujGroup('3-2', 'Realtime 오류 시 오프라인 바 표시', () {
    cujCase(
      'edge: todayActiveEventsProvider 오류 → 오프라인 표시',
      app: const Scaffold(body: EventNowBar()),
      overrides: () => [
        todayActiveEventsProvider.overrideWith(
          (ref) async => throw Exception('network error'),
        ),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('(오프라인)'), findsOneWidget);
      },
    );
  });
}
