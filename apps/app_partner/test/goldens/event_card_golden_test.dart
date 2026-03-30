@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/party/event/widgets/event_card.dart';
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
  final baseEvent = Event(
    id: 'e1',
    partyId: 'p1',
    startTime: baseTime,
    endTime: baseTime.add(const Duration(hours: 2)),
    createdAt: baseTime,
    updatedAt: baseTime,
    title: '금요 파티',
    currentParticipants: 12,
  );

  goldenTest(
    'scheduled',
    fileName: 'event_card_scheduled',
    pumpBeforeTest: pumpAndDumpTree('event_card_scheduled'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'scheduled',
          child: GoldenComponentWrapper(
            child: EventCard(event: baseEvent, onTap: () {}),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'full capacity',
    fileName: 'event_card_full',
    pumpBeforeTest: pumpAndDumpTree('event_card_full'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'full capacity',
          child: GoldenComponentWrapper(
            child: EventCard(
              event: baseEvent.copyWith(currentParticipants: 20),
              onTap: () {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'no title (default)',
    fileName: 'event_card_no_title',
    pumpBeforeTest: pumpAndDumpTree('event_card_no_title'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'no title',
          child: GoldenComponentWrapper(
            child: EventCard(
              event: baseEvent.copyWith(title: null),
              onTap: () {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'scheduled (dark)',
    fileName: 'event_card_scheduled_dark',
    pumpBeforeTest: pumpAndDumpTree('event_card_scheduled_dark'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'scheduled (dark)',
          child: GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: EventCard(event: baseEvent, onTap: () {}),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'full capacity (dark)',
    fileName: 'event_card_full_dark',
    pumpBeforeTest: pumpAndDumpTree('event_card_full_dark'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'full capacity (dark)',
          child: GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: EventCard(
              event: baseEvent.copyWith(currentParticipants: 20),
              onTap: () {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'no title (default) (dark)',
    fileName: 'event_card_no_title_dark',
    pumpBeforeTest: pumpAndDumpTree('event_card_no_title_dark'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'no title (dark)',
          child: GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: EventCard(
              event: baseEvent.copyWith(title: null),
              onTap: () {},
            ),
          ),
        ),
      ],
    ),
  );
}
