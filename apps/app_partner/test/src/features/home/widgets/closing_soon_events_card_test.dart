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
  });
}
