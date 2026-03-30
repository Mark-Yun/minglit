import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/event_feed_type.dart';
import 'package:minglit_kit/src/data/models/ticket.dart';
import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:minglit_kit/src/logic/providers/event_feed_provider.dart';
import 'package:minglit_kit/src/logic/providers/user_profile_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockEvent extends Mock implements Event {}

/// Helper to create a real Event for ticket-related tests.
Event _createEvent({
  String id = 'event-1',
  List<Ticket>? tickets,
}) {
  final now = DateTime.now();
  return Event(
    id: id,
    partyId: 'party-1',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    tickets: tickets,
  );
}

Ticket _createTicket({String id = 'ticket-1', String name = 'General'}) {
  final now = DateTime.now();
  return Ticket(
    id: id,
    name: name,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(EventFeedType.nearest);
  });

  group('fetchEventFeedProvider', () {
    test('returns list of events when repository returns data', () async {
      final mockRepo = MockEventRepository();
      final mockEvent = MockEvent();

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          blockedPartnerIds: any(named: 'blockedPartnerIds'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [mockEvent]);

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWith((ref) => mockRepo)],
      );

      final result = await container.read(
        fetchEventFeedProvider(type: EventFeedType.newArrivals).future,
      );

      expect(result, hasLength(1));
      expect(result.first, mockEvent);
    });

    test('returns empty list when repository returns empty', () async {
      final mockRepo = MockEventRepository();

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          blockedPartnerIds: any(named: 'blockedPartnerIds'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWith((ref) => mockRepo)],
      );

      final result = await container.read(
        fetchEventFeedProvider(type: EventFeedType.closingSoon).future,
      );

      expect(result, isEmpty);
    });

    test('provider enters error state when repository throws', () async {
      final mockRepo = MockEventRepository();

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          blockedPartnerIds: any(named: 'blockedPartnerIds'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(Exception('Network error'));

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWith((ref) => mockRepo)],
      );

      // Wait for the provider to settle into error state
      await expectLater(
        container.read(
          fetchEventFeedProvider(type: EventFeedType.nearest).future,
        ),
        throwsA(anything),
      );
    });
  });

  // Fix #778: Regression tests — eventFeed must return all events regardless
  // of ticket configuration. The previous implementation filtered out events
  // without tickets for logged-in users.
  group('eventFeedProvider — ticket filter regression (#778)', () {
    late MockEventRepository mockRepo;

    setUp(() {
      mockRepo = MockEventRepository();
    });

    test('returns events with empty tickets when user is logged in', () async {
      final event = _createEvent(tickets: []);

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          blockedPartnerIds: any(named: 'blockedPartnerIds'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [event]);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWith((ref) => mockRepo),
          currentUserProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'user-1',
              name: 'Test User',
              username: 'testuser',
            ),
          ),
        ],
      );

      final result = await container.read(
        eventFeedProvider(type: EventFeedType.newArrivals).future,
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'event-1');
    });

    test('returns events with null tickets when user is logged in', () async {
      final event = _createEvent();

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          blockedPartnerIds: any(named: 'blockedPartnerIds'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [event]);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWith((ref) => mockRepo),
          currentUserProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'user-1',
              name: 'Test User',
              username: 'testuser',
            ),
          ),
        ],
      );

      final result = await container.read(
        eventFeedProvider(type: EventFeedType.newArrivals).future,
      );

      expect(result, hasLength(1));
      expect(result.first.tickets, isNull);
    });

    test('returns events with tickets when user is logged in', () async {
      final event = _createEvent(
        tickets: [_createTicket()],
      );

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          blockedPartnerIds: any(named: 'blockedPartnerIds'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [event]);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWith((ref) => mockRepo),
          currentUserProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'user-1',
              name: 'Test User',
              username: 'testuser',
            ),
          ),
        ],
      );

      final result = await container.read(
        eventFeedProvider(type: EventFeedType.newArrivals).future,
      );

      expect(result, hasLength(1));
      expect(result.first.tickets, hasLength(1));
    });

    test(
      'returns mixed events (with and without tickets) for logged-in user',
      () async {
        final eventWithTickets = _createEvent(
          id: 'event-with-tickets',
          tickets: [_createTicket()],
        );
        final eventWithoutTickets = _createEvent(
          id: 'event-without-tickets',
          tickets: [],
        );
        final eventNullTickets = _createEvent(
          id: 'event-null-tickets',
        );

        when(
          () => mockRepo.getEventsByType(
            type: any(named: 'type'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            limit: any(named: 'limit'),
            blockedPartnerIds: any(named: 'blockedPartnerIds'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer(
          (_) async => [
            eventWithTickets,
            eventWithoutTickets,
            eventNullTickets,
          ],
        );

        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWith((ref) => mockRepo),
            currentUserProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: 'user-1',
                name: 'Test User',
                username: 'testuser',
              ),
            ),
          ],
        );

        final result = await container.read(
          eventFeedProvider(type: EventFeedType.newArrivals).future,
        );

        expect(
          result,
          hasLength(3),
          reason:
              'All events should be returned '
              'regardless of ticket configuration',
        );
      },
    );

    test('returns events when user is not logged in', () async {
      final event = _createEvent(tickets: []);

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          blockedPartnerIds: any(named: 'blockedPartnerIds'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [event]);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWith((ref) => mockRepo),
          currentUserProfileProvider.overrideWith((ref) async => null),
        ],
      );

      final result = await container.read(
        eventFeedProvider(type: EventFeedType.newArrivals).future,
      );

      expect(result, hasLength(1));
    });
  });

  group('eventDetailProvider', () {
    test('returns event when repository returns data', () async {
      final mockRepo = MockEventRepository();
      final mockEvent = MockEvent();

      when(
        () => mockRepo.getEventById(any()),
      ).thenAnswer((_) async => mockEvent);

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWith((ref) => mockRepo)],
      );

      final result = await container.read(
        eventDetailProvider('test-event-id').future,
      );

      expect(result, mockEvent);
    });
  });
}
