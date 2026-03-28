@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/home/widgets/closing_soon_events_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  // Use a fixed date so the golden file is deterministic.
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
    'single event',
    fileName: 'closing_soon_single',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'single event',
          child: GoldenComponentWrapper(
            child: ClosingSoonEventsCard(
              events: [makeEvent('e1', '금요 파티', 1)],
              onEventTap: (_) {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'multiple events',
    fileName: 'closing_soon_multiple',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'multiple events',
          child: GoldenComponentWrapper(
            child: ClosingSoonEventsCard(
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
    'single event (dark)',
    fileName: 'closing_soon_single_dark',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'single event (dark)',
          child: GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: ClosingSoonEventsCard(
              events: [makeEvent('e1', '금요 파티', 1)],
              onEventTap: (_) {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'multiple events (dark)',
    fileName: 'closing_soon_multiple_dark',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'multiple events (dark)',
          child: GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: ClosingSoonEventsCard(
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
