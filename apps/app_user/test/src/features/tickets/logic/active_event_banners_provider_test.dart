import 'package:app_user/src/features/tickets/active_event_banners_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockMatchingRepository mockMatchingRepo;
  late MockUser mockUser;

  // Provider uses DateTime.now() internally, so event times must be relative
  // to wall-clock time to avoid spurious isCompletedLike evaluations.
  Event makeEvent({
    String id = 'event-1',
    String status = 'active',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final base = DateTime.now();
    return Event(
      id: id,
      partyId: 'party-1',
      title: '테스트 이벤트',
      status: status,
      startTime: startTime ?? base.add(const Duration(hours: 1)),
      endTime: endTime ?? base.add(const Duration(hours: 3)),
      createdAt: base,
      updatedAt: base,
    );
  }

  EventApplication makeApplication({
    String id = 'app-1',
    String eventId = 'event-1',
    String status = 'approved',
    DateTime? matchResultsViewedAt,
    Event? event,
  }) {
    final base = DateTime.now();
    return EventApplication(
      id: id,
      eventId: eventId,
      ticketId: 'ticket-1',
      userId: 'user-1',
      status: status,
      createdAt: base,
      updatedAt: base,
      matchResultsViewedAt: matchResultsViewedAt,
      event: event,
    );
  }

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockMatchingRepo = MockMatchingRepository();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user-1');
  });

  ProviderContainer makeContainer() {
    return createContainer(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        matchingRepositoryProvider.overrideWith((ref) => mockMatchingRepo),
      ],
    );
  }

  group('activeEventBannersProvider', () {
    test('null user returns empty list', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          matchingRepositoryProvider.overrideWith((ref) => mockMatchingRepo),
        ],
      );

      final result = await container.read(activeEventBannersProvider.future);
      expect(result, isEmpty);
    });

    test('noShow overrides all other state', () async {
      final event = makeEvent(status: 'ongoing');
      final application = makeApplication(event: event);

      when(
        () => mockEventRepo.getMyTickets('user-1'),
      ).thenAnswer((_) async => [application]);
      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
      ).thenAnswer(
        (_) async => [
          TodayActiveEvent(event: event, participantStatus: 'no_show'),
        ],
      );
      when(
        () => mockMatchingRepo.getMyMatches('event-1'),
      ).thenAnswer((_) async => []);

      final container = makeContainer();
      final result = await container.read(activeEventBannersProvider.future);

      expect(result, hasLength(1));
      expect(result.first.phase, EventLifecyclePhase.noShow);
    });

    test(
      'matchingReady when checked-in + ongoing + candidates + no votes',
      () async {
        final event = makeEvent(status: 'ongoing');
        final application = makeApplication(event: event);

        when(
          () => mockEventRepo.getMyTickets('user-1'),
        ).thenAnswer((_) async => [application]);
        when(
          () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
        ).thenAnswer(
          (_) async => [
            TodayActiveEvent(event: event, participantStatus: 'checked_in'),
          ],
        );
        when(
          () => mockMatchingRepo.getMyMatches('event-1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockMatchingRepo.getMatchingCandidates('event-1'),
        ).thenAnswer((_) async => [MockUserProfile()]);
        // Fix #2123: zero votes → matchingReady, not matching
        when(
          () => mockMatchingRepo.getMyVoteCount('event-1'),
        ).thenAnswer((_) async => 0);

        final container = makeContainer();
        final result = await container.read(activeEventBannersProvider.future);

        expect(result, hasLength(1));
        expect(result.first.phase, EventLifecyclePhase.matchingReady);
      },
    );

    test('matching when checked-in + ongoing + voteCount > 0', () async {
      final event = makeEvent(status: 'ongoing');
      final application = makeApplication(event: event);

      when(
        () => mockEventRepo.getMyTickets('user-1'),
      ).thenAnswer((_) async => [application]);
      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
      ).thenAnswer(
        (_) async => [
          TodayActiveEvent(event: event, participantStatus: 'checked_in'),
        ],
      );
      when(
        () => mockMatchingRepo.getMyMatches('event-1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMatchingCandidates('event-1'),
      ).thenAnswer((_) async => [MockUserProfile()]);
      // Fix #2123: at least one vote → matching phase
      when(
        () => mockMatchingRepo.getMyVoteCount('event-1'),
      ).thenAnswer((_) async => 1);

      final container = makeContainer();
      final result = await container.read(activeEventBannersProvider.future);

      expect(result, hasLength(1));
      expect(result.first.phase, EventLifecyclePhase.matching);
    });

    test('checkedIn when checked-in but event not ongoing', () async {
      final event = makeEvent(status: 'active');
      final application = makeApplication(event: event);

      when(
        () => mockEventRepo.getMyTickets('user-1'),
      ).thenAnswer((_) async => [application]);
      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
      ).thenAnswer(
        (_) async => [
          TodayActiveEvent(event: event, participantStatus: 'checked_in'),
        ],
      );
      when(
        () => mockMatchingRepo.getMyMatches('event-1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMatchingCandidates('event-1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMyVoteCount('event-1'),
      ).thenAnswer((_) async => 0);

      final container = makeContainer();
      final result = await container.read(activeEventBannersProvider.future);

      expect(result, hasLength(1));
      expect(result.first.phase, EventLifecyclePhase.checkedIn);
    });

    test(
      'resultsUnviewed for completed event with no matchResultsViewedAt',
      () async {
        final event = makeEvent(status: 'completed');
        final application = makeApplication(
          event: event,
          matchResultsViewedAt: null,
        );

        when(
          () => mockEventRepo.getMyTickets('user-1'),
        ).thenAnswer((_) async => [application]);
        when(
          () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockMatchingRepo.getMyMatches('event-1'),
        ).thenAnswer((_) async => [_makeMatchPair()]);

        final container = makeContainer();
        final result = await container.read(activeEventBannersProvider.future);

        expect(result, hasLength(1));
        expect(result.first.phase, EventLifecyclePhase.resultsUnviewed);
      },
    );

    test(
      'resultsViewed for completed event when matchResultsViewedAt set',
      () async {
        final event = makeEvent(status: 'completed');
        final application = makeApplication(
          event: event,
          matchResultsViewedAt: DateTime.now().subtract(
            const Duration(hours: 1),
          ),
        );

        when(
          () => mockEventRepo.getMyTickets('user-1'),
        ).thenAnswer((_) async => [application]);
        when(
          () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockMatchingRepo.getMyMatches('event-1'),
        ).thenAnswer((_) async => [_makeMatchPair()]);

        final container = makeContainer();
        final result = await container.read(activeEventBannersProvider.future);

        expect(result, hasLength(1));
        expect(result.first.phase, EventLifecyclePhase.resultsViewed);
      },
    );

    test('ended items are filtered out of results', () async {
      final endedEvent = makeEvent(
        status: 'completed',
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final application = makeApplication(event: endedEvent);

      when(
        () => mockEventRepo.getMyTickets('user-1'),
      ).thenAnswer((_) async => [application]);
      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMyMatches('event-1'),
      ).thenAnswer((_) async => []);

      final container = makeContainer();
      final result = await container.read(activeEventBannersProvider.future);

      expect(result, isEmpty);
    });

    test('higher-urgency phases sort before lower-urgency ones', () async {
      final base = DateTime.now();
      // event-a: scheduled + future start → waiting (rank 4)
      final eventA = makeEvent(
        id: 'event-a',
        status: 'scheduled',
        startTime: base.add(const Duration(hours: 2)),
        endTime: base.add(const Duration(hours: 4)),
      );
      // event-b: active + checked-in → checkedIn (rank 3)
      final eventB = makeEvent(
        id: 'event-b',
        status: 'active',
        startTime: base.add(const Duration(hours: 1)),
        endTime: base.add(const Duration(hours: 3)),
      );

      final appA = makeApplication(
        id: 'app-a',
        eventId: 'event-a',
        event: eventA,
      );
      final appB = makeApplication(
        id: 'app-b',
        eventId: 'event-b',
        event: eventB,
      );

      when(
        () => mockEventRepo.getMyTickets('user-1'),
      ).thenAnswer((_) async => [appA, appB]);
      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
      ).thenAnswer(
        (_) async => [
          TodayActiveEvent(event: eventB, participantStatus: 'checked_in'),
        ],
      );
      when(
        () => mockMatchingRepo.getMyMatches('event-a'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMyMatches('event-b'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMatchingCandidates('event-b'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMyVoteCount('event-b'),
      ).thenAnswer((_) async => 0);

      final container = makeContainer();
      final result = await container.read(activeEventBannersProvider.future);

      // checkedIn (rank 3) sorts before waiting (rank 4)
      expect(result[0].phase, EventLifecyclePhase.checkedIn);
      expect(result[1].phase, EventLifecyclePhase.waiting);
    });

    test(
      'getMyMatches exception propagates as provider error state',
      () async {
        // Regression for Fix #2123: getMyMatches errors must surface as provider
        // error state, not silently downgrade phase.
        final event = makeEvent(status: 'ongoing');
        final application = makeApplication(event: event);

        when(
          () => mockEventRepo.getMyTickets('user-1'),
        ).thenAnswer((_) async => [application]);
        when(
          () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
        ).thenAnswer(
          (_) async => [
            TodayActiveEvent(event: event, participantStatus: 'checked_in'),
          ],
        );
        when(
          () => mockMatchingRepo.getMyMatches('event-1'),
        ).thenAnswer((_) async => throw Exception('matches error'));
        when(
          () => mockMatchingRepo.getMatchingCandidates('event-1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockMatchingRepo.getMyVoteCount('event-1'),
        ).thenAnswer((_) async => 0);

        final container = makeContainer();
        Object? caught;
        try {
          await container.read(activeEventBannersProvider.future);
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<Exception>());
      },
    );

    test(
      'getMatchingCandidates exception silently defaults: phase is checkedIn',
      () async {
        // Verifies the silent-catch path: getMatchingCandidates errors are swallowed
        // and hasMatchingCandidates = false, so phase falls back to checkedIn.
        final event = makeEvent(status: 'ongoing');
        final application = makeApplication(event: event);

        when(
          () => mockEventRepo.getMyTickets('user-1'),
        ).thenAnswer((_) async => [application]);
        when(
          () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
        ).thenAnswer(
          (_) async => [
            TodayActiveEvent(event: event, participantStatus: 'checked_in'),
          ],
        );
        when(
          () => mockMatchingRepo.getMyMatches('event-1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockMatchingRepo.getMatchingCandidates('event-1'),
        ).thenAnswer((_) async => throw Exception('candidates error'));
        when(
          () => mockMatchingRepo.getMyVoteCount('event-1'),
        ).thenAnswer((_) async => 0);

        final container = makeContainer();
        final result = await container.read(activeEventBannersProvider.future);

        expect(result, hasLength(1));
        expect(result.first.phase, EventLifecyclePhase.checkedIn);
      },
    );
  });

  group('waiting vs checkInReady transition', () {
    test(
      'waiting when start time is in the future and status is scheduled',
      () async {
        final base = DateTime.now();
        final event = makeEvent(
          status: 'scheduled',
          startTime: base.add(const Duration(hours: 2)),
          endTime: base.add(const Duration(hours: 4)),
        );
        final application = makeApplication(event: event);

        when(
          () => mockEventRepo.getMyTickets('user-1'),
        ).thenAnswer((_) async => [application]);
        when(
          () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockMatchingRepo.getMyMatches('event-1'),
        ).thenAnswer((_) async => []);

        final container = makeContainer();
        final result = await container.read(activeEventBannersProvider.future);

        expect(result.first.phase, EventLifecyclePhase.waiting);
      },
    );

    test('checkInReady when event status is active', () async {
      final base = DateTime.now();
      final event = makeEvent(
        status: 'active',
        startTime: base.subtract(const Duration(minutes: 10)),
        endTime: base.add(const Duration(hours: 2)),
      );
      final application = makeApplication(event: event);

      when(
        () => mockEventRepo.getMyTickets('user-1'),
      ).thenAnswer((_) async => [application]);
      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user-1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMyMatches('event-1'),
      ).thenAnswer((_) async => []);

      final container = makeContainer();
      final result = await container.read(activeEventBannersProvider.future);

      expect(result.first.phase, EventLifecyclePhase.checkInReady);
    });
  });
}

MatchPair _makeMatchPair() => MatchPair(
  matchId: 'match-1',
  eventId: 'event-1',
  partnerId: 'partner-1',
  matchedAt: DateTime.now(),
);
