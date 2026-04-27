// Fix #1925: partnerContact (phone number) must be masked in ResultsContent UI.
// Personal phone numbers are sensitive PII under 개인정보보호법 §24.

import 'package:app_user/src/common/widgets/match_results_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final testEvent = Event(
    id: 'event-1',
    partyId: 'party-1',
    title: '테스트 이벤트',
    startTime: DateTime.now().subtract(const Duration(hours: 2)),
    endTime: DateTime.now().add(const Duration(hours: 1)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final activeEvent = TodayActiveEvent(
    event: testEvent,
    participantStatus: 'ticket_issued',
  );

  Widget buildWidget({required List<MatchPair> matches}) {
    return ProviderScope(
      overrides: [
        myMatchesProvider(testEvent.id).overrideWith(
          (ref, eventId) async => matches,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MatchResultsContent(activeEvent: activeEvent),
        ),
      ),
    );
  }

  group('MatchResultsContent — phone masking (Fix #1925)', () {
    testWidgets('partnerContact is masked — raw phone not shown', (
      tester,
    ) async {
      const rawPhone = '01012345678';
      final match = MatchPair(
        matchId: 'match-1',
        eventId: testEvent.id,
        partnerId: 'partner-1',
        matchedAt: DateTime.now(),
        partnerName: '홍길동',
        partnerContact: rawPhone,
      );

      await tester.pumpWidget(buildWidget(matches: [match]));
      await tester.pumpAndSettle();

      // Raw phone must not appear
      expect(
        find.text(rawPhone),
        findsNothing,
        reason: 'Raw phone number must not be displayed (PII)',
      );

      // Masked version must appear
      expect(find.text('010-****-5678'), findsOneWidget);
    });

    testWidgets('+82 country-code phone is also masked correctly', (
      tester,
    ) async {
      const rawPhone = '+821012345678';
      final match = MatchPair(
        matchId: 'match-2',
        eventId: testEvent.id,
        partnerId: 'partner-2',
        matchedAt: DateTime.now(),
        partnerName: '김철수',
        partnerContact: rawPhone,
      );

      await tester.pumpWidget(buildWidget(matches: [match]));
      await tester.pumpAndSettle();

      expect(find.text(rawPhone), findsNothing);
      expect(find.text('010-****-5678'), findsOneWidget);
    });

    testWidgets('null partnerContact renders no phone text', (tester) async {
      final match = MatchPair(
        matchId: 'match-3',
        eventId: testEvent.id,
        partnerId: 'partner-3',
        matchedAt: DateTime.now(),
        partnerName: '이영희',
      );

      await tester.pumpWidget(buildWidget(matches: [match]));
      await tester.pumpAndSettle();

      // Partner name should appear but no masked-phone text
      expect(find.text('이영희'), findsOneWidget);
      expect(find.textContaining('****'), findsNothing);
    });
  });
}
