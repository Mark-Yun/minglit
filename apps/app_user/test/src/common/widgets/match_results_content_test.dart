import 'dart:async';

import 'package:app_user/src/common/widgets/match_results_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final testEvent = Event(
    id: 'event-1',
    partyId: 'party-1',
    title: '테스트 이벤트',
    startTime: DateTime(2026, 5, 1, 18),
    endTime: DateTime(2026, 5, 1, 21),
    createdAt: DateTime(2026, 5, 1, 16),
    updatedAt: DateTime(2026, 5, 1, 16),
  );

  final activeEvent = TodayActiveEvent(
    event: testEvent,
    participantStatus: 'ticket_issued',
  );

  MatchPair buildMatch({
    required String id,
    required String name,
    required String phone,
  }) {
    return MatchPair(
      matchId: id,
      eventId: testEvent.id,
      partnerId: 'partner-$id',
      matchedAt: DateTime(2026, 5, 1, 20),
      partnerName: name,
      partnerContact: phone,
    );
  }

  Widget buildWidget({
    required Future<List<MatchPair>> Function() loadMatches,
    Future<void> Function(MatchPair match)? onSaveContact,
    VoidCallback? onNavigateHome,
    bool reduceMotion = false,
  }) {
    return ProviderScope(
      overrides: [
        myMatchesProvider(testEvent.id).overrideWith(
          (ref) => loadMatches(),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: MatchResultsContent(
              activeEvent: activeEvent,
              onSaveContact: onSaveContact,
              onNavigateHome: onNavigateHome,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('loading state shows progress slot', (tester) async {
    final completer = Completer<List<MatchPair>>();

    await tester.pumpWidget(
      buildWidget(loadMatches: () => completer.future),
    );

    expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'single match shows centered card with full contact and no pager',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          loadMatches: () async => [
            buildMatch(id: '1', name: '김민지', phone: '010-1234-5678'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1명과 매칭되었어요!'), findsOneWidget);
      expect(
        find.textContaining('매칭된 상대방에게 서로의 연락처가 공유되었습니다.'),
        findsOneWidget,
      );
      expect(find.text('010-1234-5678'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.widgetWithText(ElevatedButton, '연락처 저장하기'), findsOneWidget);
    },
  );

  testWidgets('multi match shows horizontal pager and indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        loadMatches: () async => [
          buildMatch(id: '1', name: '김민지', phone: '010-1234-5678'),
          buildMatch(id: '2', name: '이준호', phone: '010-9911-1188'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2명과 매칭되었어요!'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('김민지'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('이준호'), findsOneWidget);
  });

  testWidgets(
    'save button calls injected contact save flow for tapped partner',
    (
      tester,
    ) async {
      MatchPair? savedMatch;

      await tester.pumpWidget(
        buildWidget(
          loadMatches: () async => [
            buildMatch(id: '1', name: '김민지', phone: '010-1234-5678'),
          ],
          onSaveContact: (match) async {
            savedMatch = match;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, '연락처 저장하기'));
      await tester.pump();

      expect(savedMatch, isNotNull);
      expect(savedMatch!.partnerName, '김민지');
      expect(savedMatch!.partnerContact, '010-1234-5678');
    },
  );

  testWidgets('empty state uses fallback copy and next-event CTA', (
    tester,
  ) async {
    var navigatedHome = false;

    await tester.pumpWidget(
      buildWidget(
        loadMatches: () async => const <MatchPair>[],
        onNavigateHome: () {
          navigatedHome = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('좋은 인연은 한번에 정해지지 않으니까요.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '다음 이벤트 찾기'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '다음 이벤트 찾기'));
    await tester.pump();

    expect(navigatedHome, isTrue);
  });

  testWidgets('error state hides error detail and uses empty fallback UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        loadMatches: () async => throw Exception('internal failure detail'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('좋은 인연은 한번에 정해지지 않으니까요.'), findsOneWidget);
    expect(find.textContaining('internal failure detail'), findsNothing);
  });

  testWidgets('reduce-motion renders final matched layout without delay', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        loadMatches: () async => [
          buildMatch(id: '1', name: '박수빈', phone: '010-4567-9012'),
        ],
        reduceMotion: true,
      ),
    );

    await tester.pump();

    expect(find.text('1명과 매칭되었어요!'), findsOneWidget);
    expect(find.text('박수빈'), findsOneWidget);
  });
}
