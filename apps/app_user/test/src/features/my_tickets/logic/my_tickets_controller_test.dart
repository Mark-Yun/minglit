import 'package:app_user/src/features/my_tickets/logic/my_tickets_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

EventApplication _makeTicket({
  required String id,
  required DateTime startTime,
  String status = 'paid',
}) {
  return EventApplication(
    id: id,
    eventId: 'event_$id',
    ticketId: 'ticket_$id',
    userId: 'user_1',
    status: status,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    event: Event(
      id: 'event_$id',
      partyId: 'party_1',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 2)),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  );
}

void main() {
  late MockEventRepository mockEventRepository;
  late MockUser mockUser;

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_1');
  });

  ProviderContainer createContainer({bool loggedIn = true}) {
    return ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => loggedIn ? mockUser : null,
        ),
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
      ],
    );
  }

  group('MyTicketsController', () {
    test('returns empty state when user is not logged in', () async {
      final container = createContainer(loggedIn: false);
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.upcoming, isEmpty);
      expect(result.past, isEmpty);
      expect(result.todayEvent, isNull);
    });

    test('separates upcoming and past tickets by startTime', () async {
      final now = DateTime.now();
      final upcoming1 = _makeTicket(
        id: 'a',
        startTime: now.add(const Duration(days: 3)),
      );
      final upcoming2 = _makeTicket(
        id: 'b',
        startTime: now.add(const Duration(days: 1)),
      );
      final past1 = _makeTicket(
        id: 'c',
        startTime: now.subtract(const Duration(days: 1)),
      );
      final past2 = _makeTicket(
        id: 'd',
        startTime: now.subtract(const Duration(days: 5)),
      );

      when(
        () => mockEventRepository.getMyTickets('user_1'),
      ).thenAnswer((_) async => [upcoming1, upcoming2, past1, past2]);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.upcoming, hasLength(2));
      expect(result.past, hasLength(2));
    });

    test('sorts upcoming ASC (closest first)', () async {
      final now = DateTime.now();
      final far = _makeTicket(
        id: 'far',
        startTime: now.add(const Duration(days: 10)),
      );
      final close = _makeTicket(
        id: 'close',
        startTime: now.add(const Duration(days: 1)),
      );
      final mid = _makeTicket(
        id: 'mid',
        startTime: now.add(const Duration(days: 5)),
      );

      when(
        () => mockEventRepository.getMyTickets('user_1'),
      ).thenAnswer((_) async => [far, close, mid]);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.upcoming[0].id, 'close');
      expect(result.upcoming[1].id, 'mid');
      expect(result.upcoming[2].id, 'far');
    });

    test('sorts past DESC (most recent first)', () async {
      final now = DateTime.now();
      final recent = _makeTicket(
        id: 'recent',
        startTime: now.subtract(const Duration(days: 1)),
      );
      final old = _makeTicket(
        id: 'old',
        startTime: now.subtract(const Duration(days: 10)),
      );
      final mid = _makeTicket(
        id: 'mid',
        startTime: now.subtract(const Duration(days: 5)),
      );

      when(
        () => mockEventRepository.getMyTickets('user_1'),
      ).thenAnswer((_) async => [recent, old, mid]);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.past[0].id, 'recent');
      expect(result.past[1].id, 'mid');
      expect(result.past[2].id, 'old');
    });

    test('detects todayEvent as most imminent event today', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final earlier = _makeTicket(
        id: 'early',
        startTime: todayStart.add(
          const Duration(hours: 23, minutes: 50),
        ),
      );
      final later = _makeTicket(
        id: 'late',
        startTime: todayStart.add(
          const Duration(hours: 23, minutes: 55),
        ),
      );

      when(
        () => mockEventRepository.getMyTickets('user_1'),
      ).thenAnswer((_) async => [later, earlier]);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.todayEvent, isNotNull);
      expect(result.todayEvent!.id, 'early');
    });

    test('todayEvent is null when no events today', () async {
      final now = DateTime.now();
      final tomorrow = _makeTicket(
        id: 'tomorrow',
        startTime: now.add(const Duration(days: 2)),
      );

      when(
        () => mockEventRepository.getMyTickets('user_1'),
      ).thenAnswer((_) async => [tomorrow]);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.todayEvent, isNull);
    });

    test('handles empty ticket list', () async {
      when(
        () => mockEventRepository.getMyTickets('user_1'),
      ).thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.upcoming, isEmpty);
      expect(result.past, isEmpty);
      expect(result.todayEvent, isNull);
    });

    test('tickets without event go to past', () async {
      final noEvent = EventApplication(
        id: 'no_event',
        eventId: 'event_1',
        ticketId: 'ticket_1',
        userId: 'user_1',
        status: 'paid',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      when(
        () => mockEventRepository.getMyTickets('user_1'),
      ).thenAnswer((_) async => [noEvent]);

      final container = createContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.upcoming, isEmpty);
      expect(result.past, hasLength(1));
      expect(result.past[0].id, 'no_event');
    });
  });
}
