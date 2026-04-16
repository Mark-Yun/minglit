// Ref #1312: IT-U05 — 매칭 투표 → 결과 확인 통합 테스트
//
// 검증 포인트:
// 1. 빈 후보자 목록 — 안내 문구 표시
// 2. 후보자 목록 렌더링 — 이름 표시
// 3. 잔여 투표 수 표시 — 남은 투표 카운터
// 4. 투표 완료 상태 — 투표 완료! 배지 표시
// 5. 매칭 성공 시 — 매칭 성공 섹션 표시
// 6. 매칭 없음 — 매칭 성공 섹션 미표시
// 7. 투표 메타 에러 — 에러 안내 표시
// 8. 이미 투표한 후보 — 투표 완료 버튼 비활성화
// 9. 투표 버튼 탭 → 확인 다이얼로그 표시
import 'dart:async';

import 'package:app_user/src/common/widgets/matching_vote_content.dart';
import 'package:app_user/src/features/event/matching/matching_vote_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/golden_capture.dart';

const _testEventId = 'test-event-u05';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Widget buildVoteContent({
    List<UserProfile> candidates = const [],
    List<MatchPair> matches = const [],
    int voteCount = 0,
    int maxVoteCount = 3,
    Set<String> votedIds = const {},
    bool metaHasError = false,
    MatchingVoteController Function()? controllerFactory,
  }) {
    return ProviderScope(
      overrides: [
        matchCandidatesProvider(_testEventId).overrideWith(
          (ref) async => candidates,
        ),
        myMatchesProvider(_testEventId).overrideWith(
          (ref) async => matches,
        ),
        myVoteCountProvider(_testEventId).overrideWith(
          (ref) async {
            if (metaHasError) throw Exception('vote meta error');
            return voteCount;
          },
        ),
        maxVoteCountProvider(_testEventId).overrideWith(
          (ref) async {
            if (metaHasError) throw Exception('vote meta error');
            return maxVoteCount;
          },
        ),
        myVotedCandidateIdsProvider(_testEventId).overrideWith(
          (ref) async {
            if (metaHasError) throw Exception('vote meta error');
            return votedIds;
          },
        ),
        matchingVoteControllerProvider.overrideWith(
          controllerFactory ?? _FakeVoteController.new,
        ),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const Scaffold(
          body: MatchingVoteContent(eventId: _testEventId),
        ),
      ),
    );
  }

  group('IT-U05: 매칭 투표 → 결과 확인', () {
    // Fix #1458: cuj_u07 → cuj_u05 to match IT-U05 scenario ID
    final capture = GoldenCapture('cuj_u05');

    testWidgets('빈 후보자 목록 — 안내 문구 표시', (tester) async {
      await tester.pumpWidget(buildVoteContent());
      await tester.pumpAndSettle();

      await capture.setup(tester, 0);

      expect(find.text('투표 가능한 상대가 없습니다.'), findsOneWidget);
    });

    testWidgets('후보자 목록 렌더링 — 이름 표시', (tester) async {
      final candidates = [
        const UserProfile(id: 'u1', name: '박민준', username: ''),
        const UserProfile(id: 'u2', name: '이서연', username: ''),
      ];

      await tester.pumpWidget(buildVoteContent(candidates: candidates));
      await tester.pumpAndSettle();

      await capture.before(tester, 1);

      expect(find.text('박민준'), findsOneWidget);
      expect(find.text('이서연'), findsOneWidget);
    });

    testWidgets('잔여 투표 수 표시 — 남은 투표 카운터', (tester) async {
      await tester.pumpWidget(
        buildVoteContent(voteCount: 1),
      );
      await tester.pumpAndSettle();

      expect(find.text('남은 투표: 2/3'), findsOneWidget);
    });

    testWidgets('투표 완료 상태 — 투표 완료! 배지 표시', (tester) async {
      await tester.pumpWidget(
        buildVoteContent(voteCount: 3),
      );
      await tester.pumpAndSettle();

      expect(find.text('투표 완료!'), findsOneWidget);
    });

    testWidgets('매칭 성공 시 — 매칭 성공 섹션 표시', (tester) async {
      final matches = [
        MatchPair(
          matchId: 'm1',
          eventId: _testEventId,
          partnerId: 'p1',
          matchedAt: DateTime(2026, 4),
          partnerName: '김지우',
        ),
      ];

      await tester.pumpWidget(buildVoteContent(matches: matches));
      await tester.pumpAndSettle();

      await capture.after(tester, 3);

      expect(find.text('매칭 성공! (1명)'), findsOneWidget);
      expect(find.text('김지우'), findsOneWidget);
    });

    testWidgets('매칭 없음 — 매칭 성공 섹션 미표시', (tester) async {
      await tester.pumpWidget(buildVoteContent());
      await tester.pumpAndSettle();

      expect(find.textContaining('매칭 성공'), findsNothing);
    });

    testWidgets('투표 메타 에러 — 에러 안내 표시', (tester) async {
      await tester.pumpWidget(buildVoteContent(metaHasError: true));
      await tester.pumpAndSettle();

      await capture.error(tester, 4);

      expect(find.text('투표 정보를 불러올 수 없습니다.'), findsOneWidget);
    });

    testWidgets('이미 투표한 후보 — 투표 완료 버튼 비활성화', (tester) async {
      final candidates = [
        const UserProfile(id: 'u1', name: '최준혁', username: ''),
      ];

      await tester.pumpWidget(
        buildVoteContent(
          candidates: candidates,
          votedIds: {'u1'},
          voteCount: 1,
        ),
      );
      await tester.pumpAndSettle();

      // 이미 투표한 후보는 '투표 완료' 버튼 텍스트 표시 (비활성화)
      expect(find.text('투표 완료'), findsOneWidget);
      // '선택' 버튼은 없음
      expect(find.text('선택'), findsNothing);
      // Fix #1312: 비활성화된 버튼이 실제로 동작하지 않는지 확인
      // onPressed: null 이므로 탭해도 확인 다이얼로그가 열리지 않아야 함
      await tester.tap(find.text('투표 완료'));
      await tester.pump();
      expect(find.text('투표하기'), findsNothing);
    });

    testWidgets('투표 버튼 탭 → 확인 다이얼로그 표시 + 투표하기 탭 → vote() 호출', (tester) async {
      final spy = _SpyVoteController();
      final candidates = [
        const UserProfile(id: 'u1', name: '정수아', username: ''),
      ];

      await tester.pumpWidget(
        buildVoteContent(
          candidates: candidates,
          controllerFactory: () => spy,
        ),
      );
      await tester.pumpAndSettle();

      // '선택' 버튼 탭 → 확인 다이얼로그 표시
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      expect(find.text('투표하기'), findsOneWidget);

      // '투표하기' 탭 → vote() 실제 호출 검증
      await tester.tap(find.text('투표하기'));
      await tester.pumpAndSettle();

      await capture.after(tester, 2);

      expect(spy.wasVoteCalled, isTrue);
      expect(spy.lastCandidateId, 'u1');
    });
  });
}

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

/// Spy controller that records vote() calls for assertion in tests.
class _SpyVoteController extends MatchingVoteController {
  bool wasVoteCalled = false;
  String? lastCandidateId;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> vote({
    required String eventId,
    required String candidateId,
  }) async {
    wasVoteCalled = true;
    lastCandidateId = candidateId;
    state = const AsyncData(null);
  }
}
