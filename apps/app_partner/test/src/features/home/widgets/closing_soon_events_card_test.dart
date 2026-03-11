import 'package:app_partner/src/features/home/widgets/closing_soon_events_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('ClosingSoonEventsCard', () {
    testWidgets('renders nothing when events empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosingSoonEventsCard(events: const [], onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('마감임박'), findsNothing);
    });

    testWidgets('shows events with D-N badge when events exist', (
      tester,
    ) async {
      final now = DateTime.now();
      final events = [
        Event(
          id: 'e1',
          partyId: 'p1',
          startTime: now.add(const Duration(days: 2)),
          endTime: now.add(const Duration(days: 2, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '마감 임박 이벤트',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosingSoonEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('마감임박'), findsOneWidget);
      expect(find.text('마감 임박 이벤트'), findsOneWidget);
    });

    testWidgets('shows multiple event titles when multiple events given', (
      tester,
    ) async {
      final now = DateTime.now();
      final events = [
        Event(
          id: 'e1',
          partyId: 'p1',
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '첫 번째 이벤트',
        ),
        Event(
          id: 'e2',
          partyId: 'p1',
          startTime: now.add(const Duration(days: 2)),
          endTime: now.add(const Duration(days: 2, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '두 번째 이벤트',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosingSoonEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('첫 번째 이벤트'), findsOneWidget);
      expect(find.text('두 번째 이벤트'), findsOneWidget);
    });

    testWidgets('shows warning icon when events exist', (tester) async {
      final now = DateTime.now();
      final events = [
        Event(
          id: 'e1',
          partyId: 'p1',
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '이벤트',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosingSoonEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('shows D-0 badge for event starting today', (tester) async {
      final now = DateTime.now();
      final events = [
        Event(
          id: 'e1',
          partyId: 'p1',
          startTime: now,
          endTime: now.add(const Duration(hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '오늘 이벤트',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosingSoonEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('D-0'), findsOneWidget);
    });

    testWidgets('shows D-2 badge for event two days away', (tester) async {
      final now = DateTime.now();
      // Use noon of the day 2 days from now to avoid inDays timing edge cases
      final twoDaysFromNow = DateTime(now.year, now.month, now.day + 2, 12);
      final events = [
        Event(
          id: 'e1',
          partyId: 'p1',
          startTime: twoDaysFromNow,
          endTime: twoDaysFromNow.add(const Duration(hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '이틀 후 이벤트',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosingSoonEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('D-2'), findsOneWidget);
    });
  });
}
