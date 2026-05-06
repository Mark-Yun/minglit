import 'package:app_user/src/features/tickets/widgets/event_ongoing_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final now = DateTime(2026, 5, 6, 19);

  EventApplication makeApplication() {
    return EventApplication(
      id: '11111111-1111-4111-8111-111111111111',
      eventId: 'event_1',
      ticketId: 'ticket_1',
      userId: 'user_1',
      status: 'approved',
      createdAt: now,
      updatedAt: now,
      event: Event(
        id: 'event_1',
        partyId: 'party_1',
        title: '강남 밍글링',
        startTime: now,
        endTime: now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
        location: Location(
          id: 'loc_1',
          partnerId: 'partner_1',
          name: '강남 라운지',
          address: '서울시 강남구',
          createdAt: now,
          updatedAt: now,
          latitude: 37.0,
          longitude: 127.0,
        ),
      ),
      ticket: Ticket(
        id: 'ticket_1',
        name: '일반 티켓',
        createdAt: now,
        updatedAt: now,
        eventId: 'event_1',
        price: 0,
        quantity: 10,
        soldCount: 1,
      ),
    );
  }

  Widget buildWidget(EventLifecyclePhase phase) {
    return MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: Scaffold(
        body: EventOngoingBanner(
          application: makeApplication(),
          phase: phase,
          onMarkResultsViewed: () {},
        ),
      ),
    );
  }

  testWidgets('waiting phase shows 입장 QR 미리 보기', (tester) async {
    await tester.pumpWidget(buildWidget(EventLifecyclePhase.waiting));

    expect(find.text('입장 QR 미리 보기'), findsOneWidget);
  });

  testWidgets('checkInReady phase shows 입장 QR 보기', (tester) async {
    await tester.pumpWidget(buildWidget(EventLifecyclePhase.checkInReady));

    expect(find.text('입장 QR 보기'), findsOneWidget);
  });

  testWidgets('noShow phase has no action button', (tester) async {
    await tester.pumpWidget(buildWidget(EventLifecyclePhase.noShow));

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('resultsUnviewed phase shows 매칭 결과 보기', (tester) async {
    await tester.pumpWidget(buildWidget(EventLifecyclePhase.resultsUnviewed));

    expect(find.text('매칭 결과 보기'), findsOneWidget);
  });

  testWidgets('checkedIn phase shows disabled 즐거운 시간 보내세요', (tester) async {
    await tester.pumpWidget(buildWidget(EventLifecyclePhase.checkedIn));

    expect(find.text('즐거운 시간 보내세요'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '즐거운 시간 보내세요'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('matching phase shows disabled 매칭 결과를 기다리고 있습니다', (tester) async {
    await tester.pumpWidget(buildWidget(EventLifecyclePhase.matching));

    expect(find.text('매칭 결과를 기다리고 있습니다'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '매칭 결과를 기다리고 있습니다'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('resultsUnviewed tap calls onMarkResultsViewed exactly once', (
    tester,
  ) async {
    var callCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: Scaffold(
          body: EventOngoingBanner(
            application: makeApplication(),
            phase: EventLifecyclePhase.resultsUnviewed,
            onMarkResultsViewed: () => callCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('매칭 결과 보기'));
    await tester.pump();

    // Navigation fails in test context (no GoRouter), but callback fires first.
    tester.takeException();

    expect(callCount, 1);
  });

  group('urgencyRank', () {
    test('higher-priority phases sort earlier', () {
      expect(EventLifecyclePhase.checkInReady.urgencyRank, 1);
      expect(EventLifecyclePhase.matchingReady.urgencyRank, 1);
      expect(EventLifecyclePhase.resultsUnviewed.urgencyRank, 1);
      expect(
        EventLifecyclePhase.matching.urgencyRank,
        lessThan(EventLifecyclePhase.resultsViewed.urgencyRank),
      );
      expect(
        EventLifecyclePhase.resultsViewed.urgencyRank,
        lessThan(EventLifecyclePhase.checkedIn.urgencyRank),
      );
      expect(
        EventLifecyclePhase.checkedIn.urgencyRank,
        lessThan(EventLifecyclePhase.waiting.urgencyRank),
      );
      expect(
        EventLifecyclePhase.waiting.urgencyRank,
        lessThan(EventLifecyclePhase.noShow.urgencyRank),
      );
      expect(EventLifecyclePhase.ended.urgencyRank, 7);
    });
  });
}
