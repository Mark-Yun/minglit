// Ref #1314: IT-U07 Event Now Bar 상태 전이 통합 테스트
//
// 검증 포인트:
// TC-U07-001: 오늘 active 이벤트 있을 때 EventNowBar 표시
// TC-U07-002: 오늘 active 이벤트 없을 때 EventNowBar 콘텐츠 숨김
// TC-U07-003: EventNowBar 탭 → EventNowBottomSheet 열림
// TC-U07-004: WAITING 상태 → '곧 시작' 텍스트
// TC-U07-005: CHECK_IN_READY 상태 → '체크인하세요' 텍스트
// TC-U07-006: CHECKED_IN 상태 → '체크인 완료' 텍스트
// TC-U07-007: MATCHING 상태 → '매칭 진행 중' 텍스트
// TC-U07-008: RESULTS 상태 → '결과 확인' 텍스트
// TC-U07-009: ENDED 상태 → '종료됨' 텍스트
//
// 테스트 전략:
// - EventNowBar를 직접 MaterialApp 내에 배치하여 렌더링을 검증한다.
// - todayActiveEventsProvider와 eventNowBarStateProvider를 ProviderScope
//   overrides로 주입하여 상태별 텍스트와 visibility를 검증한다.
import 'dart:async';

import 'package:app_user/src/features/home/widgets/event_now_bar.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:app_user/src/features/home/widgets/event_now_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final testEvent = Event(
    id: 'event-u07',
    partyId: 'party-u07',
    title: '오늘의 이벤트',
    startTime: DateTime(2026, 5, 1, 19),
    endTime: DateTime(2026, 5, 1, 21),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final activeEvent = TodayActiveEvent(
    event: testEvent,
    participantStatus: 'ticket_issued',
  );

  Widget buildBar(
    EventNowBarState state, {
    List<TodayActiveEvent>? events,
  }) {
    final eventList = events ?? [activeEvent];
    return ProviderScope(
      overrides: [
        todayActiveEventsProvider.overrideWith((ref) async => eventList),
        if (eventList.isNotEmpty)
          eventNowBarStateProvider(eventList.first).overrideWith(
            () => _FakeEventNowBarStateNotifier(state),
          ),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: EventNowBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('IT-U07 Event Now Bar 상태 전이 CUJ', () {
    // TC-U07-001: 이벤트 있을 때 나우바 표시
    testWidgets(
      'TC-U07-001: 오늘 active 이벤트가 있으면 EventNowBar가 표시된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.waiting));
        await tester.pump(); // provider 시작
        await tester.pump(); // AsyncData → 리빌드

        expect(find.byType(EventNowBar), findsOneWidget);
        expect(find.text('오늘의 이벤트'), findsOneWidget);
      },
    );

    // TC-U07-002: 이벤트 없을 때 나우바 콘텐츠 숨김
    testWidgets(
      'TC-U07-002: 오늘 active 이벤트가 없으면 EventNowBar 콘텐츠가 표시되지 않는다',
      (tester) async {
        await tester.pumpWidget(
          buildBar(EventNowBarState.waiting, events: []),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('오늘의 이벤트'), findsNothing);
        expect(find.text('곧 시작'), findsNothing);
      },
    );

    // TC-U07-003: 나우바 탭 → 바텀시트 열림
    testWidgets(
      'TC-U07-003: EventNowBar를 탭하면 EventNowBottomSheet가 열린다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.checkInReady));
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('오늘의 이벤트'));
        await tester.pump(); // 바텀시트 show 시작
        await tester.pump(const Duration(milliseconds: 300)); // 슬라이드 애니메이션

        expect(find.byType(EventNowBottomSheet), findsOneWidget);
      },
    );

    // TC-U07-004: WAITING → '곧 시작'
    testWidgets(
      'TC-U07-004: WAITING 상태에서 "곧 시작" 텍스트가 표시된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.waiting));
        await tester.pump();
        await tester.pump();

        expect(find.text('곧 시작'), findsOneWidget);
      },
    );

    // TC-U07-005: CHECK_IN_READY → '체크인하세요'
    testWidgets(
      'TC-U07-005: CHECK_IN_READY 상태에서 "체크인하세요" 텍스트가 표시된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.checkInReady));
        await tester.pump();
        await tester.pump();

        expect(find.text('체크인하세요'), findsOneWidget);
      },
    );

    // TC-U07-006: CHECKED_IN → '체크인 완료'
    testWidgets(
      'TC-U07-006: CHECKED_IN 상태에서 "체크인 완료" 텍스트가 표시된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.checkedIn));
        await tester.pump();
        await tester.pump();

        expect(find.text('체크인 완료'), findsOneWidget);
      },
    );

    // TC-U07-007: MATCHING → '매칭 진행 중'
    testWidgets(
      'TC-U07-007: MATCHING 상태에서 "매칭 진행 중" 텍스트가 표시된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.matching));
        await tester.pump();
        await tester.pump();

        expect(find.text('매칭 진행 중'), findsOneWidget);
      },
    );

    // TC-U07-008: RESULTS → '결과 확인'
    testWidgets(
      'TC-U07-008: RESULTS 상태에서 "결과 확인" 텍스트가 표시된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.results));
        await tester.pump();
        await tester.pump();

        expect(find.text('결과 확인'), findsOneWidget);
      },
    );

    // TC-U07-009: ENDED → '종료됨'
    testWidgets(
      'TC-U07-009: ENDED 상태에서 "종료됨" 텍스트가 표시된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.ended));
        await tester.pump();
        await tester.pump();

        expect(find.text('종료됨'), findsOneWidget);
      },
    );
  });
}

/// 테스트용 EventNowBarStateNotifier — 지정된 상태를 즉시 반환한다.
class _FakeEventNowBarStateNotifier extends EventNowBarStateNotifier {
  _FakeEventNowBarStateNotifier(this._state);

  final EventNowBarState _state;

  @override
  FutureOr<EventNowBarState> build(TodayActiveEvent activeEvent) async =>
      _state;
}
