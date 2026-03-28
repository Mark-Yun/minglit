// Fix #467: minglit_kit 공유 위젯 골든테스트 추가 (EventCard 5종)
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Wraps a widget in MaterialApp + Scaffold for golden tests.
Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.dark
        ? MinglitTheme.materialThemeDark
        : MinglitTheme.materialTheme,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  // Use fixed dates so D-day labels are deterministic.
  final baseTime = DateTime(2026, 6, 15, 19);
  final fiveDaysBefore = DateTime(2026, 6, 10, 12);
  final now = DateTime(2026, 6, 15, 10);

  const partner = Partner(
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
    party: party,
    location: location,
    tickets: [ticket],
  );

  // Loading skeleton uses infinite animation (shimmer), so use pumpNTimes
  // instead of default pumpAndSettle to avoid timeout.
  goldenTest(
    'loading skeleton',
    fileName: 'event_card_loading',
    pumpBeforeTest: pumpNTimes(4),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'loading skeleton',
          child: SizedBox(
            width: 390,
            height: 300,
            child: _wrap(const MinglitEventCard.loading()),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'full data',
    fileName: 'event_card_full_data',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'full data',
          child: SizedBox(
            width: 390,
            height: 300,
            child: _wrap(
              MinglitEventCard(
                event: fullDataEvent,
                currentTime: fiveDaysBefore,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'sold out (max capacity)',
    fileName: 'event_card_sold_out',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'sold out',
          child: SizedBox(
            width: 390,
            height: 300,
            child: _wrap(
              MinglitEventCard(
                event: fullDataEvent.copyWith(
                  currentParticipants: 20,
                  maxParticipants: 20,
                ),
                currentTime: fiveDaysBefore,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'today event (D-day)',
    fileName: 'event_card_today',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'today event',
          child: SizedBox(
            width: 390,
            height: 300,
            child: _wrap(
              MinglitEventCard(
                event: fullDataEvent.copyWith(
                  startTime: now.add(const Duration(hours: 5)),
                  endTime: now.add(const Duration(hours: 8)),
                  currentParticipants: 3,
                ),
                currentTime: now,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'dark theme',
    fileName: 'event_card_dark',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'dark theme',
          child: SizedBox(
            width: 390,
            height: 300,
            child: _wrap(
              MinglitEventCard(
                event: fullDataEvent,
                currentTime: fiveDaysBefore,
              ),
              brightness: Brightness.dark,
            ),
          ),
        ),
      ],
    ),
  );
}
