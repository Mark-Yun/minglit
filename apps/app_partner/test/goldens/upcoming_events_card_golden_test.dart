@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/home/widgets/upcoming_events_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final baseTime = DateTime(2026, 4, 15, 19);

  Event makeEvent(String id, String title, int daysFromBase) {
    final start = baseTime.add(Duration(days: daysFromBase));
    return Event(
      id: id,
      partyId: 'p1',
      startTime: start,
      endTime: start.add(const Duration(hours: 2)),
      createdAt: baseTime,
      updatedAt: baseTime,
      title: title,
    );
  }

  goldenTest(
    'empty state',
    fileName: 'upcoming_events_empty',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'empty state',
          child: GoldenComponentWrapper(
            child: UpcomingEventsCard(events: const [], onEventTap: (_) {}),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'with events',
    fileName: 'upcoming_events_with_data',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'with events',
          child: GoldenComponentWrapper(
            child: UpcomingEventsCard(
              events: [
                makeEvent('e1', '금요 파티', 1),
                makeEvent('e2', '토요 모임', 2),
                makeEvent('e3', '일요 브런치', 3),
              ],
              onEventTap: (_) {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'empty state (dark)',
    fileName: 'upcoming_events_empty_dark',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'empty state (dark)',
          child: GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: UpcomingEventsCard(events: const [], onEventTap: (_) {}),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'with events (dark)',
    fileName: 'upcoming_events_with_data_dark',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'with events (dark)',
          child: GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: UpcomingEventsCard(
              events: [
                makeEvent('e1', '금요 파티', 1),
                makeEvent('e2', '토요 모임', 2),
                makeEvent('e3', '일요 브런치', 3),
              ],
              onEventTap: (_) {},
            ),
          ),
        ),
      ],
    ),
  );
}
