// CUJ tests — event-operation / matching-results-reveal (app_user)
//
// 대응 spec: docs/features/event-operation/matching-results-reveal/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'dart:async';

import 'package:app_user/src/common/widgets/match_results_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/cuj_test.dart';

class _ResultsSheetHarness extends StatelessWidget {
  const _ResultsSheetHarness({
    required this.activeEvent,
    required this.entryLabel,
  });

  final TodayActiveEvent activeEvent;
  final String entryLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            unawaited(
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (sheetContext) => SafeArea(
                  child: MatchResultsContent(activeEvent: activeEvent),
                ),
              ),
            );
          },
          child: Text(entryLabel),
        ),
      ),
    );
  }
}

Event _makeEvent({String id = 'event-1', String? title = '매칭 테스트 이벤트'}) =>
    Event(
      id: id,
      partyId: 'party-1',
      startTime: DateTime(2026, 6, 1, 19),
      endTime: DateTime(2026, 6, 1, 22),
      createdAt: DateTime(2026, 6, 1, 10),
      updatedAt: DateTime(2026, 6, 1, 10),
      title: title,
    );

TodayActiveEvent _makeActiveEvent({String id = 'event-1', String? title}) =>
    TodayActiveEvent(
      event: _makeEvent(id: id, title: title),
      participantStatus: 'checked_in',
    );

MatchPair _makeMatch({
  required String id,
  required String partnerId,
  String? partnerName,
  String? partnerContact = '01012345678',
}) => MatchPair(
  matchId: id,
  eventId: 'event-1',
  partnerId: partnerId,
  matchedAt: DateTime(2026, 6, 1, 22),
  partnerName: partnerName,
  partnerContact: partnerContact,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 홈 결과 surface에서 매칭 결과 열기
  // ---------------------------------------------------------------------------
  cujGroup('1-1', '홈 결과 surface에서 매칭 결과 열기', () {
    cujCase(
      'happy: 홈 surface 탭 시 결과 sheet가 열리고 match 카드가 보인다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '홈 결과 열기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) async => [
            _makeMatch(id: 'm-1', partnerId: 'p-1', partnerName: '민지'),
          ],
        ),
      ],
      body: (t) async {
        await t.tap(find.text('홈 결과 열기'));
        await t.pumpAndSettle();

        expect(find.text('매칭 결과'), findsOneWidget);
        expect(find.text('1명과 매칭되었어요!'), findsOneWidget);
        expect(find.text('민지'), findsOneWidget);
      },
    );

    cujCase(
      'edge: sheet 오픈 직후 provider pending이면 로딩 인디케이터가 보인다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '홈 결과 열기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith((ref) {
          return Future<List<MatchPair>>.delayed(
            const Duration(seconds: 1),
            () => [_makeMatch(id: 'm-2', partnerId: 'p-2', partnerName: '지수')],
          );
        }),
      ],
      afterPump: (t) async => t.pump(),
      body: (t) async {
        await t.tap(find.text('홈 결과 열기'));
        await t.pump();
        expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 이벤트 상세에서 매칭 결과 열기
  // ---------------------------------------------------------------------------
  cujGroup('1-2', '이벤트 상세에서 매칭 결과 열기', () {
    cujCase(
      'happy: 이벤트 상세 진입 버튼 탭 시 동일 결과 sheet가 열린다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(title: '상세 이벤트'),
        entryLabel: '상세 결과 보기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) async => [
            _makeMatch(id: 'm-3', partnerId: 'p-3', partnerName: '하늘'),
          ],
        ),
      ],
      body: (t) async {
        await t.tap(find.text('상세 결과 보기'));
        await t.pumpAndSettle();

        expect(find.text('매칭 결과'), findsOneWidget);
        expect(find.text('상세 이벤트'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 이벤트 타이틀이 없으면 fallback 타이틀 "이벤트"가 노출된다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '상세 결과 보기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) async => [
            _makeMatch(id: 'm-4', partnerId: 'p-4', partnerName: '나래'),
          ],
        ),
      ],
      body: (t) async {
        await t.tap(find.text('상세 결과 보기'));
        await t.pumpAndSettle();

        expect(find.text('이벤트'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 단일 매칭 연락처 표시/저장 대상 검증
  // ---------------------------------------------------------------------------
  cujGroup('1-3', '단일 매칭 결과 표시', () {
    cujCase(
      'happy: 단일 매칭이면 1명 카운트 + 파트너 정보가 표시된다',
      app: const Scaffold(body: SizedBox.shrink()),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) async => [
            _makeMatch(id: 'm-5', partnerId: 'p-5', partnerName: '도윤'),
          ],
        ),
      ],
      body: (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              myMatchesProvider('event-1').overrideWith(
                (ref) async => [
                  _makeMatch(id: 'm-5', partnerId: 'p-5', partnerName: '도윤'),
                ],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MatchResultsContent(activeEvent: _makeActiveEvent()),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('1명과 매칭되었어요!'), findsOneWidget);
        expect(find.text('도윤'), findsOneWidget);
      },
    );

    cujCase(
      'edge: partnerContact가 없으면 연락처 텍스트는 표시되지 않는다',
      app: const Scaffold(body: SizedBox.shrink()),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) async => [
            _makeMatch(
              id: 'm-6',
              partnerId: 'p-6',
              partnerName: '세아',
              partnerContact: null,
            ),
          ],
        ),
      ],
      body: (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              myMatchesProvider('event-1').overrideWith(
                (ref) async => [
                  _makeMatch(
                    id: 'm-6',
                    partnerId: 'p-6',
                    partnerName: '세아',
                    partnerContact: null,
                  ),
                ],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MatchResultsContent(activeEvent: _makeActiveEvent()),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('세아'), findsOneWidget);
        expect(find.textContaining('****'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 여러 매칭 카드 탐색
  // ---------------------------------------------------------------------------
  cujGroup('2-1', '여러 매칭 카드 표시', () {
    cujCase(
      'happy: 매칭 2건이면 2명 카운트와 각 파트너 카드가 표시된다',
      app: const Scaffold(body: SizedBox.shrink()),
      body: (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              myMatchesProvider('event-1').overrideWith(
                (ref) async => [
                  _makeMatch(id: 'm-7', partnerId: 'p-7', partnerName: '은우'),
                  _makeMatch(id: 'm-8', partnerId: 'p-8', partnerName: '유나'),
                ],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MatchResultsContent(activeEvent: _makeActiveEvent()),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('2명과 매칭되었어요!'), findsOneWidget);
        expect(find.text('은우'), findsOneWidget);
        expect(find.text('유나'), findsOneWidget);
      },
    );

    cujCase(
      'edge: partnerName이 null이면 "알 수 없음" fallback이 표시된다',
      app: const Scaffold(body: SizedBox.shrink()),
      body: (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              myMatchesProvider('event-1').overrideWith(
                (ref) async => [
                  _makeMatch(id: 'm-9', partnerId: 'p-9'),
                ],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MatchResultsContent(activeEvent: _makeActiveEvent()),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('알 수 없음'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 매칭 없음 결과
  // ---------------------------------------------------------------------------
  cujGroup('3-1', '매칭 없음 empty 상태 표시', () {
    cujCase(
      'happy: 매칭 0건이면 empty 안내 문구를 표시한다',
      app: const Scaffold(body: SizedBox.shrink()),
      body: (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              myMatchesProvider('event-1').overrideWith((ref) async => []),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MatchResultsContent(activeEvent: _makeActiveEvent()),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('이번엔 아쉽지만, 다음 기회에!'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 빈 목록이어도 시트 타이틀은 유지된다',
      app: const Scaffold(body: SizedBox.shrink()),
      body: (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              myMatchesProvider('event-1').overrideWith((ref) async => []),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MatchResultsContent(activeEvent: _makeActiveEvent()),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('매칭 결과'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 조회 실패 fallback 처리
  // ---------------------------------------------------------------------------
  cujGroup('3-2', '조회 실패 시 empty fallback 처리', () {
    cujCase(
      'happy: provider error 시 empty 상태와 동일한 문구를 표시한다',
      app: const Scaffold(body: SizedBox.shrink()),
      body: (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              myMatchesProvider('event-1').overrideWith(
                (ref) =>
                    Future<List<MatchPair>>.error(Exception('load failed')),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MatchResultsContent(activeEvent: _makeActiveEvent()),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text('이번엔 아쉽지만, 다음 기회에!'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 내부 에러 메시지는 사용자에게 직접 노출되지 않는다',
      app: const Scaffold(body: SizedBox.shrink()),
      body: (t) async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              myMatchesProvider('event-1').overrideWith(
                (ref) =>
                    Future<List<MatchPair>>.error(Exception('secret details')),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MatchResultsContent(activeEvent: _makeActiveEvent()),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.textContaining('secret details'), findsNothing);
      },
    );
  });
}
