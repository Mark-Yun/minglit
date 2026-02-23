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
  });
}
