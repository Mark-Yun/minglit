@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/event/admission/payment_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  final location = Location(
    id: 'loc1',
    partnerId: 'partner1',
    name: '밍릿 라운지',
    address: '서울 강남구 테헤란로 123',
    createdAt: DateTime(2026, 4),
    updatedAt: DateTime(2026, 4),
  );
  final ticket = Ticket(
    id: 'ticket1',
    name: '프리미엄 티켓',
    price: 59000,
    createdAt: DateTime(2026, 4),
    updatedAt: DateTime(2026, 4),
  );
  final event = Event(
    id: 'event1',
    partyId: 'party1',
    title: '청담 소셜 다이닝',
    location: location,
    tickets: [ticket],
    startTime: DateTime(2026, 4, 25, 18, 30),
    endTime: DateTime(2026, 4, 25, 21, 30),
    createdAt: DateTime(2026, 4),
    updatedAt: DateTime(2026, 4),
  );

  setUpAll(() async {
    await initGoldenDeps();
  });

  goldenTest(
    'PaymentSuccessScreen states',
    fileName: 'payment_success_screen_followup_states',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'selected ticket summary',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: PaymentSuccessScreen(
                event: event,
                ticketId: 'ticket1',
                onViewTickets: () {},
                onBackToEvent: () {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'missing ticket fallback',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: PaymentSuccessScreen(
                event: event.copyWith(location: null, tickets: const []),
                ticketId: 'missing-ticket',
                onViewTickets: () {},
                onBackToEvent: () {},
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
