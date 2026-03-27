@Tags(['golden'])
library;

import 'package:app_partner/src/features/party/event/widgets/event_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('EventCard golden', () {
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

    testWidgets('scheduled', (tester) async {
      await expectGolden(
        tester,
        widget: EventCard(event: baseEvent, onTap: () {}),
        goldenFileName: 'event_card_scheduled.png',
      );
    });

    testWidgets('full capacity', (tester) async {
      await expectGolden(
        tester,
        widget: EventCard(
          event: baseEvent.copyWith(currentParticipants: 20),
          onTap: () {},
        ),
        goldenFileName: 'event_card_full.png',
      );
    });

    testWidgets('no title (default)', (tester) async {
      await expectGolden(
        tester,
        widget: EventCard(
          event: baseEvent.copyWith(title: null),
          onTap: () {},
        ),
        goldenFileName: 'event_card_no_title.png',
      );
    });

    testWidgets('scheduled (dark)', (tester) async {
      await expectGolden(
        tester,
        widget: EventCard(event: baseEvent, onTap: () {}),
        goldenFileName: 'event_card_scheduled_dark.png',
        brightness: Brightness.dark,
      );
    });

    testWidgets('full capacity (dark)', (tester) async {
      await expectGolden(
        tester,
        widget: EventCard(
          event: baseEvent.copyWith(currentParticipants: 20),
          onTap: () {},
        ),
        goldenFileName: 'event_card_full_dark.png',
        brightness: Brightness.dark,
      );
    });

    testWidgets('no title (default) (dark)', (tester) async {
      await expectGolden(
        tester,
        widget: EventCard(
          event: baseEvent.copyWith(title: null),
          onTap: () {},
        ),
        goldenFileName: 'event_card_no_title_dark.png',
        brightness: Brightness.dark,
      );
    });
  });
}
