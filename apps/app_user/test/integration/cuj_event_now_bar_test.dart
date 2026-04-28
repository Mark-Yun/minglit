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
// TC-U07-010: CHECK_IN_READY 탭 → 바텀시트에 이벤트 시간 표시
// TC-U07-011: CHECKED_IN 탭 → 바텀시트에 "체크인 완료!" 헤더 표시
// TC-U07-012: MATCHING 탭 → 바텀시트에 투표 잔여 수 표시
// TC-U07-013: RESULTS 탭 → 바텀시트에 "매칭 결과" + 빈 상태 표시
// TC-U07-014: ENDED 탭 → 바텀시트에 "이벤트가 종료되었어요" 표시
// TC-U07-015: RESULTS 상태 → pulse AnimatedBuilder 렌더링
//
// 테스트 전략:
// - EventNowBar를 직접 MaterialApp 내에 배치하여 렌더링을 검증한다.
// - todayActiveEventsProvider와 eventNowBarStateProvider를 ProviderScope
//   overrides로 주입하여 상태별 텍스트와 visibility를 검증한다.
// - 바텀시트 phase 테스트는 phase별 네트워크 프로바이더를 상태 기반 조건부
//   override로 주입하여 실제 Supabase 호출 없이 UI를 검증한다.
import 'dart:async';

import 'package:app_user/src/common/event_ticket_token_provider.dart';
import 'package:app_user/src/features/event/matching/matching_vote_controller.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:app_user/src/features/home/widgets/event_now_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/golden_capture.dart';

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

  /// 상태별 필요한 모든 프로바이더 override를 포함한 테스트 위젯 생성.
  ///
  /// [state] 에 따라 바텀시트 phase 컨텐츠 프로바이더도 조건부로 override한다:
  /// - checkInReady/waiting: eventTicketTokenProvider (null → QR 에러 위젯)
  /// - matching: vote/candidate 프로바이더 전체
  /// - results: myMatchesProvider
  Widget buildBar(
    EventNowBarState state, {
    List<TodayActiveEvent>? events,
    // MATCHING phase 파라미터
    int voteCount = 1,
    int maxVoteCount = 3,
    // RESULTS phase 파라미터
    List<MatchPair> matches = const [],
  }) {
    final eventList = events ?? [activeEvent];
    return ProviderScope(
      overrides: [
        todayActiveEventsProvider.overrideWith((ref) async => eventList),
        if (eventList.isNotEmpty)
          eventNowBarStateProvider(eventList.first).overrideWith(
            () => _FakeEventNowBarStateNotifier(state),
          ),
        // Fix #2022: prevent EventRealtime.build() from calling supabaseClientProvider
        // in integration tests where Supabase is not initialized.
        if (eventList.isNotEmpty)
          eventRealtimeProvider(eventList.first.event.id).overrideWith(
            _NoOpEventRealtime.new,
          ),
        // Phase 1: QR 토큰 프로바이더 — null 반환으로 에러 위젯 폴백
        if (state == EventNowBarState.checkInReady ||
            state == EventNowBarState.waiting)
          eventTicketTokenProvider('event-u07').overrideWith(
            (ref) async => null,
          ),
        // Phase 3: 투표/후보자 프로바이더 전체 override
        if (state == EventNowBarState.matching) ...[
          myVoteCountProvider('event-u07').overrideWith(
            (ref) async => voteCount,
          ),
          maxVoteCountProvider('event-u07').overrideWith(
            (ref) async => maxVoteCount,
          ),
          matchCandidatesProvider('event-u07').overrideWith(
            (ref) async => <UserProfile>[],
          ),
          myVotedCandidateIdsProvider('event-u07').overrideWith(
            (ref) async => <String>{},
          ),
          myMatchesProvider('event-u07').overrideWith(
            (ref) async => <MatchPair>[],
          ),
          matchingVoteControllerProvider.overrideWith(_FakeVoteController.new),
        ],
        // Phase 4: 매칭 결과 프로바이더 override
        if (state == EventNowBarState.results)
          myMatchesProvider('event-u07').overrideWith(
            (ref) async => matches,
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

  /// 바텀시트를 열기까지의 공통 준비 단계.
  ///
  /// [state] 에 맞는 바를 렌더링한 뒤 '오늘의 이벤트' 를 탭하고
  /// 슬라이드 애니메이션이 완료될 때까지 진행한다.
  Future<void> openSheet(
    WidgetTester tester,
    EventNowBarState state, {
    int voteCount = 1,
    int maxVoteCount = 3,
    List<MatchPair> matches = const [],
  }) async {
    await tester.pumpWidget(
      buildBar(
        state,
        voteCount: voteCount,
        maxVoteCount: maxVoteCount,
        matches: matches,
      ),
    );
    await tester.pump(); // provider 시작
    await tester.pump(); // AsyncData → 리빌드
    await tester.tap(find.text('오늘의 이벤트'));
    await tester.pump(); // 바텀시트 show 시작
    await tester.pump(const Duration(milliseconds: 300)); // 슬라이드 애니메이션
  }

  group('IT-U07 Event Now Bar 상태 전이 CUJ', () {
    final capture = GoldenCapture('cuj_u09');

    // TC-U07-001: 이벤트 있을 때 나우바 표시
    testWidgets(
      'TC-U07-001: 오늘 active 이벤트가 있으면 EventNowBar가 표시된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.waiting));
        await tester.pump(); // provider 시작
        await tester.pump(); // AsyncData → 리빌드

        await capture.setup(tester, 0);

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

        await capture.setup(tester, 1);

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

        await capture.after(tester, 2);

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

  group('IT-U07-B EventNowBottomSheet phase 컨텐츠 검증', () {
    final capture = GoldenCapture('cuj_u09');

    // TC-U07-010: CHECK_IN_READY → 이벤트 제목 + 시간 표시
    testWidgets(
      'TC-U07-010: CHECK_IN_READY 탭 → 바텀시트에 이벤트 제목과 시간이 표시된다',
      (tester) async {
        await openSheet(tester, EventNowBarState.checkInReady);

        expect(find.byType(EventNowBottomSheet), findsOneWidget);
        // CheckInReadyContent: 이벤트 제목 (바 + 시트 중복 렌더링)
        expect(find.text('오늘의 이벤트'), findsWidgets);
        // 날짜 포맷 "M월 d일 HH:mm" → "5월 1일 19:00"
        expect(find.textContaining('5월 1일'), findsOneWidget);

        await capture.after(tester, 3);
      },
    );

    // TC-U07-011: CHECKED_IN → "체크인 완료!" 헤더 + 대기 메시지
    testWidgets(
      'TC-U07-011: CHECKED_IN 탭 → 바텀시트에 "체크인 완료!" 헤더와 대기 메시지가 표시된다',
      (tester) async {
        await openSheet(tester, EventNowBarState.checkedIn);

        expect(find.byType(EventNowBottomSheet), findsOneWidget);
        // CheckedInContent: 체크인 완료 헤더
        expect(find.text('체크인 완료!'), findsOneWidget);
        // 매칭 대기 메시지
        expect(find.text('곧 매칭이 시작될 거예요'), findsOneWidget);
      },
    );

    // TC-U07-012: MATCHING → 남은 투표 수 표시
    testWidgets(
      'TC-U07-012: MATCHING 탭 → 바텀시트에 남은 투표 수가 표시된다',
      (tester) async {
        await openSheet(
          tester,
          EventNowBarState.matching,
        );

        expect(find.byType(EventNowBottomSheet), findsOneWidget);
        // MatchingContent: 비동기 데이터 로드 후 투표 현황
        await tester.pumpAndSettle();
        // voteCount=1, maxVoteCount=3 → 남은 투표: 2 / 3
        expect(find.text('남은 투표: 2 / 3'), findsOneWidget);
      },
    );

    // TC-U07-013: RESULTS → "매칭 결과" 헤더 + 빈 상태
    testWidgets(
      'TC-U07-013: RESULTS 탭 → 바텀시트에 "매칭 결과" 헤더와 빈 상태 메시지가 표시된다',
      (tester) async {
        await openSheet(
          tester,
          EventNowBarState.results,
          matches: [],
        );

        expect(find.byType(EventNowBottomSheet), findsOneWidget);
        // ResultsContent: 매칭 결과 헤더
        expect(find.text('매칭 결과'), findsOneWidget);
        // 매칭 없음 → 빈 상태 메시지
        // pumpAndSettle 대신 pump 사용: RESULTS 상태의 pulse 애니메이션이
        // AnimationController.repeat()으로 무한 반복하므로 settle이 불가능하다.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('이번엔 아쉽지만, 다음 기회에!'), findsOneWidget);
      },
    );

    // TC-U07-014: ENDED → "이벤트가 종료되었어요" + 리뷰 CTA
    testWidgets(
      'TC-U07-014: ENDED 탭 → 바텀시트에 "이벤트가 종료되었어요"와 리뷰 CTA가 표시된다',
      (tester) async {
        await openSheet(tester, EventNowBarState.ended);

        expect(find.byType(EventNowBottomSheet), findsOneWidget);
        // EndedContent: 종료 헤더
        expect(find.text('이벤트가 종료되었어요'), findsOneWidget);
        // 리뷰 작성 CTA 버튼
        expect(find.text('리뷰 작성하기'), findsOneWidget);
      },
    );

    // TC-U07-015: RESULTS 상태 → pulse AnimatedBuilder 렌더링
    testWidgets(
      'TC-U07-015: RESULTS 상태에서 나우바 dot에 pulse AnimatedBuilder가 렌더링된다',
      (tester) async {
        await tester.pumpWidget(buildBar(EventNowBarState.results));
        await tester.pump();
        await tester.pump();

        // _buildDot: results 상태 → pulse == true → AnimatedBuilder로 opacity 애니메이션
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
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

/// Fix #2022: No-op EventRealtime stub — prevents Supabase Realtime
/// initialization in integration tests.
class _NoOpEventRealtime extends EventRealtime {
  @override
  void build(String eventId) {}
}

/// 테스트용 MatchingVoteController — 실제 네트워크 호출 없이 즉시 성공 반환.
class _FakeVoteController extends MatchingVoteController {
  @override
  FutureOr<void> build() {}

  @override
  Future<void> vote({
    required String eventId,
    required String candidateId,
  }) async {
    state = const AsyncData(null);
  }
}
