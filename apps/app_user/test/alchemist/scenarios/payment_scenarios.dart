import 'package:app_user/src/features/event/admission/payment_success_screen.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'screenshot_scenario.dart';

class PaymentScenarios {
  static final _baseTime = DateTime(2026, 4, 2, 19);

  // --- PurchaseHistoryPage data ---

  static Location get _location => Location(
    id: 'location-1',
    partnerId: 'partner-1',
    name: '밍글릿 라운지',
    address: '서울 강남구 테헤란로 1',
    createdAt: _baseTime,
    updatedAt: _baseTime,
  );

  static Ticket get _ticket => Ticket(
    id: 'ticket-1',
    eventId: 'event-1',
    name: '얼리버드',
    price: 35000,
    quantity: 50,
    soldCount: 12,
    createdAt: _baseTime,
    updatedAt: _baseTime,
  );

  static Event get _event => Event(
    id: 'event-1',
    partyId: 'party-1',
    title: '4월 네트워킹 나이트',
    startTime: _baseTime.add(const Duration(days: 10)),
    endTime: _baseTime.add(const Duration(days: 10, hours: 3)),
    createdAt: _baseTime,
    updatedAt: _baseTime,
    location: _location,
    tickets: [_ticket],
  );

  static EventApplication get _application => EventApplication(
    id: 'application-1',
    eventId: _event.id,
    ticketId: _ticket.id,
    userId: 'user-1',
    status: 'paid',
    paymentAmount: 35000,
    createdAt: _baseTime,
    updatedAt: _baseTime,
    paidAt: _baseTime,
    event: _event,
    ticket: _ticket,
  );

  static MockUser _mockUser() {
    final user = MockUser();
    when(() => user.id).thenReturn('user-1');
    return user;
  }

  static List<dynamic> _purchaseHistoryOverrides(
    List<EventApplication> history,
  ) {
    final mockEventRepository = MockEventRepository();
    when(
      () => mockEventRepository.getMyPurchaseHistory('user-1'),
    ).thenAnswer((_) async => history);
    return [eventRepositoryProvider.overrideWithValue(mockEventRepository)];
  }

  // --- PaymentSuccessScreen data ---

  static Location get _successLocation => Location(
    id: 'location-2',
    partnerId: 'partner-2',
    name: '성수 이벤트홀',
    address: '서울 성동구 연무장길 10',
    createdAt: _baseTime,
    updatedAt: _baseTime,
  );

  static Ticket get _generalTicket => Ticket(
    id: 'ticket-general',
    eventId: 'event-success',
    name: '일반 티켓',
    price: 42000,
    createdAt: _baseTime,
    updatedAt: _baseTime,
  );

  static Event get _successEvent => Event(
    id: 'event-success',
    partyId: Party(
      id: 'party-success',
      partnerId: 'partner-2',
      title: '봄 시즌 파티',
      createdAt: _baseTime,
      updatedAt: _baseTime,
      location: _successLocation,
    ).id,
    title: '성수 스프링 밋업',
    startTime: _baseTime.add(const Duration(days: 5)),
    endTime: _baseTime.add(const Duration(days: 5, hours: 4)),
    createdAt: _baseTime,
    updatedAt: _baseTime,
    location: _successLocation,
    party: Party(
      id: 'party-success',
      partnerId: 'partner-2',
      title: '봄 시즌 파티',
      createdAt: _baseTime,
      updatedAt: _baseTime,
      location: _successLocation,
    ),
    tickets: [_generalTicket],
  );

  // All purchase history scenarios
  static List<ScreenshotScenario> get purchaseHistoryScenarios => [
    ScreenshotScenario(
      name: 'purchase_history_empty',
      page: const PurchaseHistoryPage(),
      currentUser: _mockUser(),
      overrides: _purchaseHistoryOverrides(const []),
    ),
    ScreenshotScenario(
      name: 'purchase_history_with_purchase',
      page: const PurchaseHistoryPage(),
      currentUser: _mockUser(),
      overrides: _purchaseHistoryOverrides([_application]),
    ),
  ];

  // All payment success scenarios
  static List<ScreenshotScenario> get paymentSuccessScenarios => [
    ScreenshotScenario(
      name: 'payment_success_summary',
      page: PaymentSuccessScreen(
        event: _successEvent,
        ticketId: _generalTicket.id,
        onViewTickets: () {},
        onBackToEvent: () {},
      ),
    ),
    ScreenshotScenario(
      name: 'payment_success_missing_ticket',
      page: PaymentSuccessScreen(
        event: _successEvent.copyWith(tickets: const []),
        ticketId: 'missing-ticket',
        onViewTickets: () {},
        onBackToEvent: () {},
      ),
    ),
    ScreenshotScenario(
      name: 'payment_success_missing_title_location',
      page: PaymentSuccessScreen(
        event: _successEvent.copyWith(title: null, location: null),
        ticketId: _generalTicket.id,
        onViewTickets: () {},
        onBackToEvent: () {},
      ),
    ),
  ];

  static List<ScreenshotScenario> get all => [
    ...purchaseHistoryScenarios,
    ...paymentSuccessScenarios,
  ];
}
