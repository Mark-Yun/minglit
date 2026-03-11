import 'package:app_partner/src/features/home/widgets/upcoming_events_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('UpcomingEventsCard', () {
    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingEventsCard(events: const [], onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('예정된 이벤트가 없습니다'), findsOneWidget);
      expect(find.text('다가오는 이벤트'), findsOneWidget);
    });

    testWidgets('shows event titles when events exist', (tester) async {
      final now = DateTime.now();
      final events = [
        Event(
          id: 'e1',
          partyId: 'p1',
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '테스트 이벤트',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('테스트 이벤트'), findsOneWidget);
      expect(find.text('다가오는 이벤트'), findsOneWidget);
    });

    testWidgets('shows header with calendar icon when events exist', (
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
          title: '이벤트',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows calendar icon in empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingEventsCard(events: const [], onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
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
        Event(
          id: 'e3',
          partyId: 'p1',
          startTime: now.add(const Duration(days: 3)),
          endTime: now.add(const Duration(days: 3, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '세 번째 이벤트',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('첫 번째 이벤트'), findsOneWidget);
      expect(find.text('두 번째 이벤트'), findsOneWidget);
      expect(find.text('세 번째 이벤트'), findsOneWidget);
    });

    testWidgets('does not show empty state text when events exist', (
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
          title: '이벤트 있음',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.text('예정된 이벤트가 없습니다'), findsNothing);
    });

    testWidgets('shows chevron_right icon for each event', (tester) async {
      final now = DateTime.now();
      final events = [
        Event(
          id: 'e1',
          partyId: 'p1',
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '이벤트 A',
        ),
        Event(
          id: 'e2',
          partyId: 'p1',
          startTime: now.add(const Duration(days: 2)),
          endTime: now.add(const Duration(days: 2, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: '이벤트 B',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingEventsCard(events: events, onEventTap: (_) {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });
  });
}
