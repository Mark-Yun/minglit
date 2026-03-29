import 'package:app_user/src/features/my_tickets/logic/my_tickets_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

/// Helper to create an EventApplication with an embedded Event.
EventApplication _ticket({
  required String id,
  required DateTime startTime,
  String status = 'paid',
}) {
  return EventApplication(
    id: id,
    eventId: 'event_$id',
    ticketId: 'ticket_$id',
    userId: 'test_user',
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

  setUp(() {
    mockEventRepository = MockEventRepository();
  });

  group('MyTicketsController', () {
    test('returns empty state when user is not logged in', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );
      expect(result.upcoming, isEmpty);
      expect(result.past, isEmpty);
      expect(result.todayEvent, isNull);
      expect(result.isEmpty, isTrue);
    });

    test('splits tickets into upcoming and past', () async {
      const userId = 'test_user';
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final nextWeek = now.add(const Duration(days: 7));
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));

      final tickets = [
        _ticket(id: 'a', startTime: tomorrow),
        _ticket(id: 'b', startTime: nextWeek),
        _ticket(id: 'c', startTime: yesterday),
        _ticket(id: 'd', startTime: lastWeek),
      ];

      when(
        () => mockEventRepository.getMyTickets(userId),
      ).thenAnswer((_) async => tickets);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.upcoming, hasLength(2));
      expect(result.past, hasLength(2));
      expect(result.isEmpty, isFalse);
    });

    test('upcoming sorted ascending (nearest first)', () async {
      const userId = 'test_user';
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final nextWeek = now.add(const Duration(days: 7));
      final in3Days = now.add(const Duration(days: 3));

      final tickets = [
        _ticket(id: 'far', startTime: nextWeek),
        _ticket(id: 'near', startTime: tomorrow),
        _ticket(id: 'mid', startTime: in3Days),
      ];

      when(
        () => mockEventRepository.getMyTickets(userId),
      ).thenAnswer((_) async => tickets);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.upcoming[0].id, 'near');
      expect(result.upcoming[1].id, 'mid');
      expect(result.upcoming[2].id, 'far');
    });

    test('past sorted descending (most recent first)', () async {
      const userId = 'test_user';
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      final tickets = [
        _ticket(id: 'old', startTime: lastWeek),
        _ticket(id: 'recent', startTime: yesterday),
        _ticket(id: 'mid', startTime: threeDaysAgo),
      ];

      when(
        () => mockEventRepository.getMyTickets(userId),
      ).thenAnswer((_) async => tickets);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.past[0].id, 'recent');
      expect(result.past[1].id, 'mid');
      expect(result.past[2].id, 'old');
    });

    test('detects todayEvent as most imminent event starting today', () async {
      const userId = 'test_user';
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);

      final now = DateTime.now();
      // Fix #639: Use fixed hour literals to avoid flakiness near midnight
      final todaySoon = DateTime(now.year, now.month, now.day, 22);
      final todayLate = DateTime(now.year, now.month, now.day, 23);
      final tomorrow = now.add(const Duration(days: 1));

      final tickets = [
        _ticket(id: 'today_late', startTime: todayLate),
        _ticket(id: 'today_soon', startTime: todaySoon),
        _ticket(id: 'tomorrow', startTime: tomorrow),
      ];

      when(
        () => mockEventRepository.getMyTickets(userId),
      ).thenAnswer((_) async => tickets);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.todayEvent, isNotNull);
      expect(result.todayEvent!.id, 'today_soon');
    });

    test('todayEvent is null when no events start today', () async {
      const userId = 'test_user';
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final tickets = [
        _ticket(id: 'a', startTime: tomorrow),
      ];

      when(
        () => mockEventRepository.getMyTickets(userId),
      ).thenAnswer((_) async => tickets);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.todayEvent, isNull);
    });

    test('handles empty ticket list', () async {
      const userId = 'test_user';
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);

      when(
        () => mockEventRepository.getMyTickets(userId),
      ).thenAnswer((_) async => <EventApplication>[]);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        myTicketsControllerProvider.future,
      );

      expect(result.upcoming, isEmpty);
      expect(result.past, isEmpty);
      expect(result.todayEvent, isNull);
      expect(result.isEmpty, isTrue);
    });

    test('tickets without event relation go to past', () async {
      const userId = 'test_user';
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);

      final ticketNoEvent = EventApplication(
        id: 'no_event',
        eventId: 'event_x',
        ticketId: 'ticket_x',
        userId: userId,
        status: 'paid',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        // event: null — no relation loaded
      );

      when(
        () => mockEventRepository.getMyTickets(userId),
      ).thenAnswer((_) async => [ticketNoEvent]);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
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
