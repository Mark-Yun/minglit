import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/my_tickets/ui/my_ticket_card.dart';
import 'package:app_user/src/features/my_tickets/ui/my_tickets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

class MockHomeCoordinator extends Mock implements HomeCoordinator {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
    registerFallbackValue(FakeRoute());
  });

  late MockEventRepository mockEventRepository;
  late MockUser mockUser;
  late MockHomeCoordinator mockHomeCoordinator;

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockUser = MockUser();
    mockHomeCoordinator = MockHomeCoordinator();
    when(() => mockUser.id).thenReturn('user1');
  });

  Widget createTestWidget({List<dynamic> extraOverrides = const []}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => mockUser),
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        homeCoordinatorProvider.overrideWithValue(mockHomeCoordinator),
        ...extraOverrides,
      ].cast(),
      child: const MaterialApp(
        home: MyTicketsPage(),
      ),
    );
  }

  EventApplication makeApplication({
    required String id,
    required String status,
    required DateTime startTime,
    String eventTitle = 'Test Event',
    String ticketName = '일반 입장권',
    String locationName = '강남 라운지바',
  }) {
    return EventApplication(
      id: id,
      eventId: 'event_$id',
      ticketId: 'ticket_$id',
      userId: 'user1',
      status: status,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      event: Event(
        id: 'event_$id',
        partyId: 'party1',
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 2)),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        title: eventTitle,
        location: Location(
          id: 'loc1',
          partnerId: 'partner1',
          name: locationName,
          address: '서울시 강남구',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ),
      ticket: Ticket(
        id: 'ticket_$id',
        name: ticketName,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );
  }

  Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  group('MyTicketsPage', () {
    testWidgets('renders empty state when no tickets', (tester) async {
      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      expect(find.text('내 티켓'), findsOneWidget);
      expect(find.text('아직 티켓이 없어요'), findsOneWidget);
      expect(find.text('이벤트 둘러보기'), findsOneWidget);
    });

    testWidgets('empty state CTA navigates to home', (tester) async {
      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      await tester.tap(find.text('이벤트 둘러보기'));
      verify(() => mockHomeCoordinator.goToHome()).called(1);
    });

    testWidgets('renders upcoming and past sections', (tester) async {
      final upcoming = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime.now().add(const Duration(days: 3)),
        eventTitle: '강남 소셜 파티',
      );
      final past = makeApplication(
        id: '2',
        status: 'paid',
        startTime: DateTime.now().subtract(const Duration(days: 5)),
        eventTitle: '성수 칵테일 소셜링',
        ticketName: 'VIP 입장권',
      );

      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => [upcoming, past]);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      expect(find.text('다가오는 이벤트'), findsOneWidget);
      expect(find.text('강남 소셜 파티'), findsOneWidget);
      expect(find.text('일반 입장권'), findsOneWidget);

      expect(find.text('지난 이벤트'), findsOneWidget);
      expect(find.text('성수 칵테일 소셜링'), findsOneWidget);
      expect(find.text('VIP 입장권'), findsOneWidget);
    });

    testWidgets('renders today banner when today event exists', (tester) async {
      // Create an event starting later today
      final now = DateTime.now();
      final todayEvent = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime(now.year, now.month, now.day, 23, 59),
        eventTitle: '오늘의 파티',
      );

      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => [todayEvent]);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      // Banner should show event name and time
      expect(find.text('오늘의 파티'), findsAtLeast(1));
      // Banner QR button
      expect(find.text('입장 QR'), findsAtLeast(1));
    });

    testWidgets('past cards have no QR button', (tester) async {
      final past = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime.now().subtract(const Duration(days: 5)),
        eventTitle: '종료된 이벤트',
      );

      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => [past]);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      expect(find.text('종료된 이벤트'), findsOneWidget);
      // Past cards should show "종료" chip, not QR button
      expect(find.text('종료'), findsOneWidget);
      // No QR button in past cards
      expect(find.text('입장 QR'), findsNothing);
    });

    testWidgets('upcoming cards show QR button', (tester) async {
      final upcoming = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime.now().add(const Duration(days: 3)),
        eventTitle: '다가오는 이벤트',
      );

      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => [upcoming]);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      expect(find.text('다가오는 이벤트'), findsAtLeast(1));
      expect(find.text('입장 QR'), findsOneWidget);
    });

    testWidgets('tapping card calls pushEventDetail', (tester) async {
      final upcoming = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime.now().add(const Duration(days: 3)),
        eventTitle: '탭 테스트 이벤트',
      );

      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => [upcoming]);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      await tester.tap(find.text('탭 테스트 이벤트'));
      verify(
        () => mockHomeCoordinator.pushEventDetail('event_1'),
      ).called(1);
    });

    // Fix #642: P2 — banner not shown when no todayEvent
    testWidgets('does not render today banner when no today event', (
      tester,
    ) async {
      final upcoming = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime.now().add(const Duration(days: 5)),
        eventTitle: '5일 뒤 이벤트',
      );

      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => [upcoming]);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      // Section header should appear, but no banner
      expect(find.text('다가오는 이벤트'), findsOneWidget);
      // Banner has "입장 QR" text — only card QR buttons should show
      // No "오늘" text in banner format
      expect(find.text('오늘'), findsNothing);
    });

    // Fix #642: P2 — past card has reduced opacity
    testWidgets('past cards have reduced opacity', (tester) async {
      final past = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime.now().subtract(const Duration(days: 3)),
        eventTitle: '지난 이벤트',
      );

      when(
        () => mockEventRepository.getMyTickets('user1'),
      ).thenAnswer((_) async => [past]);

      await tester.pumpWidget(createTestWidget());
      await pumpAndSettle(tester);

      // MyTicketCard wraps content in Opacity(opacity: 0.55) for past
      final opacityWidget = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(MyTicketCard),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacityWidget.opacity, 0.55);
    });
  }); // end MyTicketsPage group

  group('MyTicketCard', () {
    testWidgets('shows D-Day chip for today event', (tester) async {
      final now = DateTime(2026, 3, 29, 12);
      final app = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime(2026, 3, 29, 19),
        eventTitle: 'D-Day 이벤트',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyTicketCard(
              application: app,
              isPast: false,
              currentTime: now,
            ),
          ),
        ),
      );

      expect(find.text('D-Day'), findsOneWidget);
    });

    testWidgets('shows D-N chip for future event', (tester) async {
      final now = DateTime(2026, 3, 29, 12);
      final app = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime(2026, 4, 1, 19),
        eventTitle: 'D-3 이벤트',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyTicketCard(
              application: app,
              isPast: false,
              currentTime: now,
            ),
          ),
        ),
      );

      expect(find.text('D-3'), findsOneWidget);
    });

    testWidgets('shows 종료 chip for past event', (tester) async {
      final now = DateTime(2026, 3, 29, 12);
      final app = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime(2026, 3, 22, 18),
        eventTitle: '종료된 이벤트',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyTicketCard(
              application: app,
              isPast: true,
              currentTime: now,
            ),
          ),
        ),
      );

      expect(find.text('종료'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      final app = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime.now().add(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyTicketCard(
              application: app,
              isPast: false,
            ),
          ),
        ),
      );

      expect(find.text('결제완료'), findsOneWidget);
    });

    // Fix #642: P1 — QR button tap navigates to TicketQRScreen
    testWidgets('QR button tap pushes TicketQRScreen', (tester) async {
      final app = makeApplication(
        id: '1',
        status: 'paid',
        startTime: DateTime.now().add(const Duration(days: 3)),
        eventTitle: 'QR 테스트 이벤트',
      );

      final navigatorObserver = MockNavigatorObserver();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            navigatorObservers: [navigatorObserver],
            home: Scaffold(
              body: MyTicketCard(
                application: app,
                isPast: false,
              ),
            ),
          ),
        ),
      );

      // Fix #642: 초기 route push 이력 제거 — 탭 이후 push만 검증
      clearInteractions(navigatorObserver);

      await tester.tap(find.text('입장 QR'));
      await tester.pumpAndSettle();

      // Verify Navigator.push was called exactly once (route to TicketQRScreen)
      verify(() => navigatorObserver.didPush(any(), any())).called(1);
    });

    testWidgets('shows location name', (tester) async {
      final app = makeApplication(
        id: '1',
        status: 'approved',
        startTime: DateTime.now().add(const Duration(days: 5)),
        locationName: '홍대 와인바',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyTicketCard(
              application: app,
              isPast: false,
            ),
          ),
        ),
      );

      expect(find.text('홍대 와인바'), findsOneWidget);
      expect(find.text('승인됨'), findsOneWidget);
    });
  });
}
