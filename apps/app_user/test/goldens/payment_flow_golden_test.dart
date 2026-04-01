@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/payment/ui/payment_success_screen.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'golden_test_helpers.dart';

void main() {
  final baseTime = DateTime(2026, 4, 2, 19);
  late MockUser mockUser;
  late MockEventRepository mockEventRepository;

  setUp(() {
    mockUser = MockUser();
    mockEventRepository = MockEventRepository();
    when(() => mockUser.id).thenReturn('user-1');
  });

  List<dynamic> buildPurchaseHistoryOverrides(List<EventApplication> history) {
    when(
      () => mockEventRepository.getMyPurchaseHistory('user-1'),
    ).thenAnswer((_) async => history);

    return [eventRepositoryProvider.overrideWithValue(mockEventRepository)];
  }

  goldenTest(
    'PurchaseHistoryPage states',
    fileName: 'purchase_history_page_states',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () {
      final location = Location(
        id: 'location-1',
        partnerId: 'partner-1',
        name: '밍글릿 라운지',
        address: '서울 강남구 테헤란로 1',
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      final ticket = Ticket(
        id: 'ticket-1',
        eventId: 'event-1',
        name: '얼리버드',
        price: 35000,
        quantity: 50,
        soldCount: 12,
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      final event = Event(
        id: 'event-1',
        partyId: 'party-1',
        title: '4월 네트워킹 나이트',
        startTime: baseTime.add(const Duration(days: 10)),
        endTime: baseTime.add(const Duration(days: 10, hours: 3)),
        createdAt: baseTime,
        updatedAt: baseTime,
        location: location,
        tickets: [ticket],
      );
      final application = EventApplication(
        id: 'application-1',
        eventId: event.id,
        ticketId: ticket.id,
        userId: 'user-1',
        status: 'paid',
        paymentAmount: 35000,
        createdAt: baseTime,
        updatedAt: baseTime,
        paidAt: baseTime,
        event: event,
        ticket: ticket,
      );

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'empty history',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const PurchaseHistoryPage(),
                overrides: buildPurchaseHistoryOverrides(const []),
                currentUser: mockUser,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'history with purchase',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const PurchaseHistoryPage(),
                overrides: buildPurchaseHistoryOverrides([application]),
                currentUser: mockUser,
              ),
            ),
          ),
        ],
      );
    },
  );

  goldenTest(
    'PaymentSuccessScreen states',
    fileName: 'payment_success_screen_states',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
    },
    builder: () {
      final location = Location(
        id: 'location-2',
        partnerId: 'partner-2',
        name: '성수 이벤트홀',
        address: '서울 성동구 연무장길 10',
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      final generalTicket = Ticket(
        id: 'ticket-general',
        eventId: 'event-success',
        name: '일반 티켓',
        price: 42000,
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      final fallbackParty = Party(
        id: 'party-success',
        partnerId: 'partner-2',
        title: '봄 시즌 파티',
        createdAt: baseTime,
        updatedAt: baseTime,
        location: location,
      );
      final event = Event(
        id: 'event-success',
        partyId: fallbackParty.id,
        title: '성수 스프링 밋업',
        startTime: baseTime.add(const Duration(days: 5)),
        endTime: baseTime.add(const Duration(days: 5, hours: 4)),
        createdAt: baseTime,
        updatedAt: baseTime,
        location: location,
        party: fallbackParty,
        tickets: [generalTicket],
      );
      final missingTicketEvent = event.copyWith(
        tickets: const [],
        title: null,
        location: null,
      );

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'success summary',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: PaymentSuccessScreen(
                  event: event,
                  ticketId: generalTicket.id,
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
                  event: missingTicketEvent,
                  ticketId: 'missing-ticket',
                  onViewTickets: () {},
                  onBackToEvent: () {},
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
