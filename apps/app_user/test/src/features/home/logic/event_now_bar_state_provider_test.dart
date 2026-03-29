import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockMatchingRepository mockMatchingRepo;

  setUp(() {
    mockMatchingRepo = MockMatchingRepository();
  });

  /// Helper to create a [TodayActiveEvent] with sensible defaults.
  TodayActiveEvent makeActiveEvent({
    String id = 'event_1',
    String status = 'scheduled',
    String participantStatus = 'ticket_issued',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final now = DateTime.now();
    return TodayActiveEvent(
      event: Event(
        id: id,
        partyId: 'party_1',
        startTime: startTime ?? now.subtract(const Duration(hours: 1)),
        endTime: endTime ?? now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
        status: status,
      ),
      participantStatus: participantStatus,
    );
  }

  /// Creates a [ProviderContainer] with matching mocks pre-configured.
  ProviderContainer makeContainer({
    required String eventId,
    List<UserProfile>? candidates,
    List<MatchPair>? matches,
  }) {
    final overrides = <dynamic>[
      matchingRepositoryProvider.overrideWith((ref) => mockMatchingRepo),
    ];

    // Override matchCandidates
    if (candidates != null) {
      when(
        () => mockMatchingRepo.getMatchingCandidates(eventId),
      ).thenAnswer((_) async => candidates);
    } else {
      when(
        () => mockMatchingRepo.getMatchingCandidates(eventId),
      ).thenAnswer((_) async => throw Exception('not available'));
    }

    // Override myMatches
    if (matches != null) {
      when(
        () => mockMatchingRepo.getMyMatches(eventId),
      ).thenAnswer((_) async => matches);
    } else {
      when(
        () => mockMatchingRepo.getMyMatches(eventId),
      ).thenAnswer((_) async => throw Exception('not available'));
    }

    return createContainer(overrides: overrides);
  }

  group('eventNowBarStateProvider — 6-state 상태 머신', () {
    test('WAITING: 시작 3시간 전 ~ 시작 시간 전', () async {
      final activeEvent = makeActiveEvent(
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
      );

      final container = makeContainer(eventId: 'event_1');

      final result = await container.read(
        eventNowBarStateProvider(activeEvent).future,
      );

      expect(result, EventNowBarState.waiting);
    });

    test(
      'CHECK_IN_READY: 시작 시간 도달 + participant.status != checked_in',
      () async {
        final activeEvent = makeActiveEvent(
          startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        final container = makeContainer(eventId: 'event_1');

        final result = await container.read(
          eventNowBarStateProvider(activeEvent).future,
        );

        expect(result, EventNowBarState.checkInReady);
      },
    );

    test(
      'CHECKED_IN: participant.status = checked_in + matchCandidates 비어있음',
      () async {
        final activeEvent = makeActiveEvent(
          participantStatus: 'checked_in',
        );

        final container = makeContainer(
          eventId: 'event_1',
          candidates: [],
        );

        final result = await container.read(
          eventNowBarStateProvider(activeEvent).future,
        );

        expect(result, EventNowBarState.checkedIn);
      },
    );

    test('MATCHING: matchCandidatesProvider가 비어있지 않음', () async {
      final activeEvent = makeActiveEvent(
        participantStatus: 'checked_in',
      );

      final container = makeContainer(
        eventId: 'event_1',
        candidates: [
          const UserProfile(
            id: 'user_2',
            name: 'Test User',
            username: 'testuser',
          ),
        ],
        matches: [], // No match results yet.
      );

      final result = await container.read(
        eventNowBarStateProvider(activeEvent).future,
      );

      expect(result, EventNowBarState.matching);
    });

    test('RESULTS: myMatchesProvider 결과 존재', () async {
      final activeEvent = makeActiveEvent(
        participantStatus: 'checked_in',
      );

      final container = makeContainer(
        eventId: 'event_1',
        candidates: [
          const UserProfile(
            id: 'user_2',
            name: 'Test User',
            username: 'testuser',
          ),
        ],
        matches: [
          MatchPair(
            matchId: 'match_1',
            eventId: 'event_1',
            partnerId: 'user_2',
            matchedAt: DateTime.now(),
          ),
        ],
      );

      final result = await container.read(
        eventNowBarStateProvider(activeEvent).future,
      );

      expect(result, EventNowBarState.results);
    });

    test('ENDED: events.status = completed', () async {
      final activeEvent = makeActiveEvent(status: 'completed');

      final container = makeContainer(
        eventId: 'event_1',
        candidates: [],
        matches: [],
      );

      final result = await container.read(
        eventNowBarStateProvider(activeEvent).future,
      );

      expect(result, EventNowBarState.ended);
    });

    test('취소 이벤트: events.status = cancelled → ENDED', () async {
      final activeEvent = makeActiveEvent(status: 'cancelled');

      final container = makeContainer(
        eventId: 'event_1',
        candidates: [],
        matches: [],
      );

      final result = await container.read(
        eventNowBarStateProvider(activeEvent).future,
      );

      expect(result, EventNowBarState.ended);
    });

    test('상태 전이 순서 보장: enum 순서 확인', () {
      // Verify the enum values are in correct forward order.
      expect(EventNowBarState.waiting.index, 0);
      expect(EventNowBarState.checkInReady.index, 1);
      expect(EventNowBarState.checkedIn.index, 2);
      expect(EventNowBarState.matching.index, 3);
      expect(EventNowBarState.results.index, 4);
      expect(EventNowBarState.ended.index, 5);

      // Forward: each state has a higher index.
      for (var i = 1; i < EventNowBarState.values.length; i++) {
        expect(
          EventNowBarState.values[i].index,
          greaterThan(EventNowBarState.values[i - 1].index),
        );
      }
    });

    test('역방향 전이 불가: 다른 이벤트는 독립적으로 상태 계산', () async {
      // First reach ENDED state via completed event.
      final endedEvent = makeActiveEvent(status: 'completed');

      final container = makeContainer(
        eventId: 'event_1',
        candidates: [],
        matches: [],
      );

      final result1 = await container.read(
        eventNowBarStateProvider(endedEvent).future,
      );
      expect(result1, EventNowBarState.ended);

      // A different event (event_2) should compute its own state independently.
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_2'),
      ).thenAnswer((_) async => throw Exception('not available'));
      when(
        () => mockMatchingRepo.getMyMatches('event_2'),
      ).thenAnswer((_) async => throw Exception('not available'));

      final waitingEvent = makeActiveEvent(
        id: 'event_2',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
      );

      final result2 = await container.read(
        eventNowBarStateProvider(waitingEvent).future,
      );

      // Different event → different provider instance → starts fresh.
      expect(result2, EventNowBarState.waiting);
    });

    test('매칭 결과 0건일 때 MATCHING 유지 (빈 매칭은 아직 결과가 아님)', () async {
      // Empty matches list + non-empty candidates → MATCHING.
      final activeEvent = makeActiveEvent(
        participantStatus: 'checked_in',
      );

      final container = makeContainer(
        eventId: 'event_1',
        candidates: [
          const UserProfile(
            id: 'user_2',
            name: 'Test User',
            username: 'testuser',
          ),
        ],
        matches: [], // Empty — no results yet.
      );

      final result = await container.read(
        eventNowBarStateProvider(activeEvent).future,
      );

      // Empty matches + non-empty candidates → MATCHING (not RESULTS).
      expect(result, EventNowBarState.matching);
    });
  });
}
