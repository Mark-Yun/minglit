@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'golden_test_helpers.dart';

void main() {
  final mockUser = MockUser();

  setUpAll(() async {
    await initGoldenDeps();
    when(() => mockUser.id).thenReturn('user1');
  });

  final location = Location(
    id: 'loc1',
    partnerId: 'partner1',
    name: '밍릿 라운지',
    address: '서울 강남구 테헤란로 123',
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
  final ticket = Ticket(
    id: 'ticket1',
    name: '얼리버드 티켓',
    price: 39000,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
  final party = Party(
    id: 'party1',
    partnerId: 'partner1',
    title: '금요 프라이빗 밍글',
    location: location,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
  final event = Event(
    id: 'event1',
    partyId: 'party1',
    title: '강남 루프탑 나이트',
    location: location,
    party: party,
    tickets: [ticket],
    contactOptions: const {'phone': '010-1234-5678'},
    startTime: DateTime(2026, 4, 18, 19),
    endTime: DateTime(2026, 4, 18, 22),
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
  final history = [
    EventApplication(
      id: 'app1',
      eventId: 'event1',
      ticketId: 'ticket1',
      userId: 'user1',
      status: 'paid',
      paymentId: 'pay_123456',
      paymentAmount: 39000,
      refundStatus: 'none',
      paidAt: DateTime(2026, 4, 2, 14),
      createdAt: DateTime(2026, 4, 2, 14),
      updatedAt: DateTime(2026, 4, 2, 14),
      event: event,
      ticket: ticket,
    ),
  ];

  List<dynamic> buildOverrides(List<EventApplication> items) {
    final repository = MockEventRepository();
    when(
      () => repository.getMyPurchaseHistory('user1'),
    ).thenAnswer((_) async => items);
    return [
      currentUserProvider.overrideWith((_) => mockUser),
      eventRepositoryProvider.overrideWithValue(repository),
    ];
  }

  goldenTest(
    'PurchaseHistoryPage states',
    fileName: 'purchase_history_page_states',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'with purchase history',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const PurchaseHistoryPage(),
              overrides: buildOverrides(history),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'empty history',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const PurchaseHistoryPage(),
              overrides: buildOverrides(const []),
            ),
          ),
        ),
      ],
    ),
  );
}
