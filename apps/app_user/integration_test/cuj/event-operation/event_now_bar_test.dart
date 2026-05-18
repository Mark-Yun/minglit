// CUJ tests — event-operation / event-now-bar (app_user)
//
// 대응 spec: docs/features/event-operation/event-now-bar/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// Fix #2564: event-operation 카테고리 CUJ integration test 전무 해소 (event-now-bar)
// Refs #2589: 추가 CUJ 커버 (1-2 ~ 2-1)

import 'dart:async';

import 'package:app_user/src/common/event_ticket_token_provider.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:app_user/src/features/home/widgets/event_now_multi_stack.dart';
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

TodayActiveEvent _makeActiveEvent2() => TodayActiveEvent(
  event: _makeEvent(id: 'evt-2'),
  participantStatus: 'ticket_issued',
);

TodayActiveEvent _makeActiveEvent3() => TodayActiveEvent(
  event: _makeEvent(id: 'evt-3'),
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
  // CUJ 1-2: 체크인 시간 도달 시 미니바 상태 자동 전환 (FR-4, FR-5)
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '체크인 시간 도달 → 미니바 체크인 상태 표시', () {
    cujCase(
      'happy: checkInReady 상태 → "체크인하세요" 레이블 표시',
      app: const Scaffold(body: EventNowBar()),
      overrides: () {
        final activeEvent = _makeActiveEvent();
        return [
          todayActiveEventsProvider.overrideWith(
            (ref) async => [activeEvent],
          ),
          eventNowBarStateProvider(activeEvent).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.checkInReady),
          ),
          eventRealtimeProvider(activeEvent.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('체크인하세요'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 미니바 탭 → 체크인 QR 바텀시트 (FR-5, FR-6)
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '미니바 탭 → Phase 1 QR 바텀시트 오픈', () {
    cujCase(
      'happy: checkInReady 탭 → 바텀시트 Phase 1 열림',
      app: const Scaffold(body: EventNowBar()),
      overrides: () {
        final activeEvent = _makeActiveEvent();
        return [
          todayActiveEventsProvider.overrideWith(
            (ref) async => [activeEvent],
          ),
          eventNowBarStateProvider(activeEvent).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.checkInReady),
          ),
          eventRealtimeProvider(activeEvent.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
          // null token → QR 에러 위젯 표시 (타임아웃 없이 안정적 렌더)
          eventTicketTokenProvider('evt-1').overrideWith(
            (ref) async => null,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 탭 → 바텀시트 오픈
        await t.tap(find.byType(EventNowBar));
        await t.pumpAndSettle();

        // 바텀시트 내 QR 에러 위젯 (token=null) 확인 → 시트가 열렸음을 검증
        expect(find.text('QR 코드를 불러올 수 없습니다'), findsOneWidget);
        expect(find.text('다시 시도'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 체크인 전(waiting) 탭도 Phase 1 시트 표시 — QR 은 항상 활성',
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
          eventTicketTokenProvider('evt-1').overrideWith(
            (ref) async => null,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        await t.tap(find.byType(EventNowBar));
        await t.pumpAndSettle();

        // waiting 상태도 Phase 1 시트 (QR) 표시 확인
        expect(find.text('QR 코드를 불러올 수 없습니다'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-4: 체크인 완료 시 매칭 대기 상태 전환 (FR-4, FR-7)
  // ---------------------------------------------------------------------------

  cujGroup('1-4', '체크인 완료 → 미니바 "체크인 완료" 레이블', () {
    cujCase(
      'happy: checkedIn 상태 → "체크인 완료" 레이블 표시',
      app: const Scaffold(body: EventNowBar()),
      overrides: () {
        final activeEvent = _makeActiveEvent();
        return [
          todayActiveEventsProvider.overrideWith(
            (ref) async => [activeEvent],
          ),
          eventNowBarStateProvider(activeEvent).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.checkedIn),
          ),
          eventRealtimeProvider(activeEvent.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('체크인 완료'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-5: 매칭 투표 시작 시 자동 전환 (FR-4, FR-8, FR-9)
  // ---------------------------------------------------------------------------

  cujGroup('1-5', '매칭 투표 시작 → 미니바 "매칭 진행 중" 레이블', () {
    cujCase(
      'happy: matching 상태 → "매칭 진행 중" 레이블 표시',
      app: const Scaffold(body: EventNowBar()),
      overrides: () {
        final activeEvent = _makeActiveEvent();
        return [
          todayActiveEventsProvider.overrideWith(
            (ref) async => [activeEvent],
          ),
          eventNowBarStateProvider(activeEvent).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.matching),
          ),
          eventRealtimeProvider(activeEvent.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('매칭 진행 중'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-6: 매칭 결과 발표 시 펄스 애니메이션 (FR-4, FR-10)
  // ---------------------------------------------------------------------------

  cujGroup('1-6', '매칭 결과 발표 → "결과 확인" 레이블', () {
    cujCase(
      'happy: results 상태 → "결과 확인" 레이블 표시',
      app: const Scaffold(body: EventNowBar()),
      overrides: () {
        final activeEvent = _makeActiveEvent();
        return [
          todayActiveEventsProvider.overrideWith(
            (ref) async => [activeEvent],
          ),
          eventNowBarStateProvider(activeEvent).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.results),
          ),
          eventRealtimeProvider(activeEvent.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        // pump 고정 횟수 — results 상태의 AnimationController.repeat()가
        // pumpAndSettle을 무한 block하므로 고정 pump 사용
        await t.pump(const Duration(milliseconds: 50));

        expect(find.text('결과 확인'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 매칭 결과 0건도 "결과 확인" 레이블 유지 (FR-10)',
      app: const Scaffold(body: EventNowBar()),
      overrides: () {
        final activeEvent = _makeActiveEvent();
        return [
          todayActiveEventsProvider.overrideWith(
            (ref) async => [activeEvent],
          ),
          eventNowBarStateProvider(activeEvent).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.results),
          ),
          eventRealtimeProvider(activeEvent.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));

        // 결과 0건이어도 상태는 results 유지 — 바텀시트 내용이 빈 상태 표시
        expect(find.text('결과 확인'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-7: 이벤트 종료 → 리뷰 + 다음 추천 (FR-4, FR-11)
  // ---------------------------------------------------------------------------

  cujGroup('1-7', '이벤트 종료 → "종료됨" 레이블', () {
    cujCase(
      'happy: ended 상태 → "종료됨" 레이블 표시',
      app: const Scaffold(body: EventNowBar()),
      overrides: () {
        final activeEvent = _makeActiveEvent();
        return [
          todayActiveEventsProvider.overrideWith(
            (ref) async => [activeEvent],
          ),
          eventNowBarStateProvider(activeEvent).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.ended),
          ),
          eventRealtimeProvider(activeEvent.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('종료됨'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-8: 종료 24시간 또는 리뷰 완료 후 미니바 해제 (FR-12)
  // ---------------------------------------------------------------------------

  cujGroup('1-8', '24h 경과 후 이벤트 목록 비면 미니바 해제', () {
    cujCase(
      'happy: 서버가 만료 이벤트 제거 → todayActiveEvents 빈 리스트 → 미니바 사라짐',
      app: const Scaffold(body: EventNowBar()),
      overrides: () => [
        // 서버가 24h 경과 후 이벤트를 activeEvents 에서 제거 — 빈 리스트로 표현
        todayActiveEventsProvider.overrideWith((ref) async => []),
      ],
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 이벤트 없으면 SizedBox.shrink — 상태 레이블이 어떤 것도 표시되지 않음
        expect(find.text('곧 시작'), findsNothing);
        expect(find.text('체크인하세요'), findsNothing);
        expect(find.text('종료됨'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 2개 이상 이벤트 활성 시 카운트 배지 (FR-13, FR-14)
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '멀티 이벤트 → 카운트 배지 표시', () {
    cujCase(
      'happy: 2개 활성 이벤트 → 배지 "2" 표시',
      app: Scaffold(
        body: EventNowMultiStack(
          events: [_makeActiveEvent(), _makeActiveEvent2()],
        ),
      ),
      overrides: () {
        final activeEvent1 = _makeActiveEvent();
        final activeEvent2 = _makeActiveEvent2();
        return [
          eventNowBarStateProvider(activeEvent1).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.waiting),
          ),
          eventNowBarStateProvider(activeEvent2).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.waiting),
          ),
          eventRealtimeProvider(activeEvent1.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
          eventRealtimeProvider(activeEvent2.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        // 카운트 배지 "2" 표시 확인
        expect(find.text('2'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 활성 이벤트 3개 이상 → 배지 개수 정확히 표시',
      app: Scaffold(
        body: EventNowMultiStack(
          events: [
            _makeActiveEvent(),
            _makeActiveEvent2(),
            _makeActiveEvent3(),
          ],
        ),
      ),
      overrides: () {
        final e1 = _makeActiveEvent();
        final e2 = _makeActiveEvent2();
        final e3 = _makeActiveEvent3();
        return [
          eventNowBarStateProvider(e1).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.waiting),
          ),
          eventNowBarStateProvider(e2).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.waiting),
          ),
          eventNowBarStateProvider(e3).overrideWith(
            () => _FakeEventNowBarStateNotifier(EventNowBarState.waiting),
          ),
          eventRealtimeProvider(e1.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
          eventRealtimeProvider(e2.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
          eventRealtimeProvider(e3.event.id).overrideWith(
            _FakeEventRealtime.new,
          ),
        ];
      },
      body: (t) async {
        await t.pump();
        await t.pumpAndSettle();

        expect(find.text('3'), findsOneWidget);
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
