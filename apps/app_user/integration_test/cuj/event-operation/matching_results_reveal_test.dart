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

class _SavedContactCall {
  const _SavedContactCall({required this.partnerId, required this.phone});

  final String partnerId;
  final String phone;
}

class _ResultsSheetHarness extends StatelessWidget {
  const _ResultsSheetHarness({
    required this.activeEvent,
    required this.entryLabel,
    this.onSaveContact,
  });

  final TodayActiveEvent activeEvent;
  final String entryLabel;
  final Future<void> Function(MatchPair match)? onSaveContact;

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
                builder: (_) => SafeArea(
                  child: MatchResultsContent(
                    activeEvent: activeEvent,
                    onSaveContact: onSaveContact,
                  ),
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
    final saved = <_SavedContactCall>[];

    cujCase(
      'happy: 단일 매칭 저장 CTA 탭 시 현재 카드 1명만 저장 대상으로 전달된다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '결과 열기',
        onSaveContact: (match) async {
          saved.add(
            _SavedContactCall(
              partnerId: match.partnerId,
              phone: match.partnerContact ?? '',
            ),
          );
        },
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) async => [
            _makeMatch(id: 'm-5', partnerId: 'p-5', partnerName: '도윤'),
          ],
        ),
      ],
      body: (t) async {
        saved.clear();

        await t.tap(find.text('결과 열기'));
        await t.pumpAndSettle();

        expect(find.text('1명과 매칭되었어요!'), findsOneWidget);
        final saveButton = find.widgetWithText(MinglitButton, '연락처 저장하기');
        expect(saveButton, findsOneWidget);
        await t.tap(saveButton);
        await t.pump();

        expect(saved, hasLength(1));
        expect(saved.first.partnerId, 'p-5');
        expect(saved.first.phone, '01012345678');
      },
    );

    cujCase(
      'edge: partnerContact가 없으면 연락처 텍스트와 저장 CTA는 표시되지 않는다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '결과 열기',
      ),
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
        await t.tap(find.text('결과 열기'));
        await t.pumpAndSettle();

        expect(find.text('세아'), findsOneWidget);
        expect(find.textContaining('****'), findsNothing);
        final saveButton = t.widget<MinglitButton>(
          find.widgetWithText(MinglitButton, '연락처 저장하기'),
        );
        expect(saveButton.onPressed, isNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 여러 매칭 카드 탐색
  // ---------------------------------------------------------------------------
  cujGroup('2-1', '여러 매칭 카드 표시', () {
    final saved = <_SavedContactCall>[];

    cujCase(
      'happy: 스와이프 시 active dot이 바뀌고 저장 CTA는 active 카드 partner만 전달한다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '결과 열기',
        onSaveContact: (match) async {
          saved.add(
            _SavedContactCall(
              partnerId: match.partnerId,
              phone: match.partnerContact ?? '',
            ),
          );
        },
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) async => [
            _makeMatch(
              id: 'm-7',
              partnerId: 'p-7',
              partnerName: '은우',
              partnerContact: '01077778888',
            ),
            _makeMatch(
              id: 'm-8',
              partnerId: 'p-8',
              partnerName: '유나',
              partnerContact: '01099990000',
            ),
          ],
        ),
      ],
      body: (t) async {
        saved.clear();

        await t.tap(find.text('결과 열기'));
        await t.pumpAndSettle();

        expect(find.text('2명과 매칭되었어요!'), findsOneWidget);
        expect(find.byType(PageView), findsOneWidget);

        List<AnimatedContainer> indicatorDots() => t
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .where(
              (w) =>
                  (w.constraints?.maxHeight == 6) &&
                  ((w.constraints?.maxWidth == 18) ||
                      (w.constraints?.maxWidth == 6)) &&
                  w.decoration is BoxDecoration,
            )
            .toList();

        final beforeDots = indicatorDots();
        expect(beforeDots.length, 2);
        expect(beforeDots[0].constraints?.maxWidth, 18);
        expect(beforeDots[1].constraints?.maxWidth, 6);

        await t.drag(find.byType(PageView), const Offset(-320, 0));
        await t.pumpAndSettle();

        final afterDots = indicatorDots();
        expect(afterDots.length, 2);
        expect(afterDots[0].constraints?.maxWidth, 6);
        expect(afterDots[1].constraints?.maxWidth, 18);

        await t.tap(
          find.widgetWithText(MinglitButton, '연락처 저장하기').hitTestable().first,
        );
        await t.pump();

        expect(saved, hasLength(1));
        expect(saved.first.partnerId, 'p-8');
        expect(saved.first.phone, '01099990000');
      },
    );

    cujCase(
      'edge: partnerName이 null이면 "알 수 없음" fallback이 표시된다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '결과 열기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) async => [_makeMatch(id: 'm-9', partnerId: 'p-9')],
        ),
      ],
      body: (t) async {
        await t.tap(find.text('결과 열기'));
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
      'happy: empty state에서 다음 이벤트 찾기 CTA 탭 시 sheet dismiss + 다음 액션 콜백 실행',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '결과 열기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith((ref) async => []),
      ],
      body: (t) async {
        await t.tap(find.text('결과 열기'));
        await t.pumpAndSettle();

        expect(find.text('다음 이벤트 찾기'), findsOneWidget);

        await t.tap(find.text('다음 이벤트 찾기'));
        await t.pumpAndSettle();

        expect(find.byType(MatchResultsContent), findsNothing);
      },
    );

    cujCase(
      'edge: empty state에서도 내부 오류 상세 텍스트는 노출되지 않는다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '결과 열기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith((ref) async => []),
      ],
      body: (t) async {
        await t.tap(find.text('결과 열기'));
        await t.pumpAndSettle();

        expect(find.textContaining('Exception'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 조회 실패 fallback 처리
  // ---------------------------------------------------------------------------
  cujGroup('3-2', '조회 실패 시 empty fallback 처리', () {
    cujCase(
      'happy: provider error에서도 empty CTA가 노출되고 탭 시 dismiss된다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '결과 열기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) => Future<List<MatchPair>>.error(Exception('load failed')),
        ),
      ],
      body: (t) async {
        await t.tap(find.text('결과 열기'));
        await t.pumpAndSettle();

        expect(find.text('다음 이벤트 찾기'), findsOneWidget);

        await t.tap(find.text('다음 이벤트 찾기'));
        await t.pumpAndSettle();

        expect(find.byType(MatchResultsContent), findsNothing);
      },
    );

    cujCase(
      'edge: 내부 에러 메시지는 사용자에게 직접 노출되지 않는다',
      app: _ResultsSheetHarness(
        activeEvent: _makeActiveEvent(),
        entryLabel: '결과 열기',
      ),
      overrides: () => [
        myMatchesProvider('event-1').overrideWith(
          (ref) => Future<List<MatchPair>>.error(Exception('secret details')),
        ),
      ],
      body: (t) async {
        await t.tap(find.text('결과 열기'));
        await t.pumpAndSettle();

        expect(find.textContaining('secret details'), findsNothing);
      },
    );
  });
}
