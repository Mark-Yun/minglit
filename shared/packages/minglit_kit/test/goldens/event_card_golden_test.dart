// Fix #467: minglit_kit 공유 위젯 골든테스트 추가 (EventCard 5종)
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('MinglitEventCard golden', () {
    // Use a fixed date so D-day labels are deterministic.
    final baseTime = DateTime(2026, 6, 15, 19);
    final now = DateTime(2026, 6, 15, 10); // same day → "오늘"

    final partner = const Partner(
      id: 'partner-1',
      name: '밍글릿 라운지',
    );

    final location = Location(
      id: 'loc-1',
      partnerId: 'partner-1',
      name: '강남 라운지',
      address: '서울시 강남구',
      createdAt: baseTime,
      updatedAt: baseTime,
    );

    final party = Party(
      id: 'party-1',
      partnerId: 'partner-1',
      title: '금요일 네트워킹 파티',
      createdAt: baseTime,
      updatedAt: baseTime,
      partner: partner,
      location: location,
    );

    final ticket = Ticket(
      id: 'ticket-1',
      name: '일반 입장권',
      price: 25000,
      quantity: 20,
      createdAt: baseTime,
      updatedAt: baseTime,
    );

    final fullDataEvent = Event(
      id: 'event-1',
      partyId: 'party-1',
      startTime: baseTime,
      endTime: baseTime.add(const Duration(hours: 3)),
      createdAt: baseTime,
      updatedAt: baseTime,
      currentParticipants: 8,
      maxParticipants: 20,
      party: party,
      location: location,
      tickets: [ticket],
    );

    testWidgets('loading skeleton', (tester) async {
      await expectGolden(
        tester,
        widget: const SizedBox(
          width: 390,
          child: MinglitEventCard.loading(),
        ),
        goldenFileName: 'event_card_loading.png',
        settle: false,
      );
    });

    testWidgets('full data', (tester) async {
      await expectGolden(
        tester,
        widget: SizedBox(
          width: 390,
          child: MinglitEventCard(event: fullDataEvent),
        ),
        goldenFileName: 'event_card_full_data.png',
      );
    });

    testWidgets('sold out (max capacity)', (tester) async {
      final soldOutEvent = fullDataEvent.copyWith(
        currentParticipants: 20,
        maxParticipants: 20,
      );

      await expectGolden(
        tester,
        widget: SizedBox(
          width: 390,
          child: MinglitEventCard(event: soldOutEvent),
        ),
        goldenFileName: 'event_card_sold_out.png',
      );
    });

    testWidgets('today event (D-day = 오늘)', (tester) async {
      // startTime is same day as "now" in the widget logic — D-day shows "오늘"
      // We use a near-future time on the same day to trigger "오늘" label.
      final todayEvent = fullDataEvent.copyWith(
        startTime: now.add(const Duration(hours: 5)),
        endTime: now.add(const Duration(hours: 8)),
        currentParticipants: 3,
      );

      await expectGolden(
        tester,
        widget: SizedBox(
          width: 390,
          child: MinglitEventCard(event: todayEvent),
        ),
        goldenFileName: 'event_card_today.png',
      );
    });

    testWidgets('dark theme', (tester) async {
      await expectGolden(
        tester,
        widget: SizedBox(
          width: 390,
          child: MinglitEventCard(event: fullDataEvent),
        ),
        goldenFileName: 'event_card_dark.png',
        brightness: Brightness.dark,
      );
    });
  });
}
