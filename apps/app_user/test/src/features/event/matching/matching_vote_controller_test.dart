import 'dart:async';

import 'package:app_user/src/features/event/matching/matching_vote_controller.dart';
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

  group('MatchingVoteController', () {
    group('vote', () {
      test('calls castVote and succeeds', () async {
        when(
          () => mockMatchingRepo.castVote(
            eventId: 'event_1',
            candidateId: 'candidate_1',
          ),
        ).thenAnswer((_) async {});

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ],
        );

        final sub = container.listen(
          matchingVoteControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);
        await container.read(matchingVoteControllerProvider.future);

        final notifier = container.read(
          matchingVoteControllerProvider.notifier,
        );

        await notifier.vote(
          eventId: 'event_1',
          candidateId: 'candidate_1',
        );

        final state = container.read(matchingVoteControllerProvider);
        expect(state, isA<AsyncData<void>>());
        verify(
          () => mockMatchingRepo.castVote(
            eventId: 'event_1',
            candidateId: 'candidate_1',
          ),
        ).called(1);
      });

      test('sets error state on failure', () async {
        when(
          () => mockMatchingRepo.castVote(
            eventId: any(named: 'eventId'),
            candidateId: any(named: 'candidateId'),
          ),
        ).thenThrow(Exception('Vote failed'));

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ],
        );

        final sub = container.listen(
          matchingVoteControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);
        await container.read(matchingVoteControllerProvider.future);

        final notifier = container.read(
          matchingVoteControllerProvider.notifier,
        );

        await notifier.vote(
          eventId: 'event_1',
          candidateId: 'candidate_1',
        );

        final state = container.read(matchingVoteControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });
    });
  });

  group('matchCandidates', () {
    test('returns candidates from repository', () async {
      final candidates = [
        const UserProfile(
          id: 'user_1',
          name: 'Candidate 1',
          username: '',
          birthYear: 1995,
        ),
        const UserProfile(
          id: 'user_2',
          name: 'Candidate 2',
          username: '',
          birthYear: 1993,
        ),
      ];

      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => candidates);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final result = await container.read(
        matchCandidatesProvider('event_1').future,
      );

      expect(result, hasLength(2));
      expect(result.first.name, 'Candidate 1');
      expect(result.last.name, 'Candidate 2');
      verify(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).called(1);
    });

    test('returns empty list when no candidates', () async {
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_empty'),
      ).thenAnswer((_) async => <UserProfile>[]);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final result = await container.read(
        matchCandidatesProvider('event_empty').future,
      );

      expect(result, isEmpty);
    });

    test('propagates error when repository throws', () async {
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_err'),
      ).thenAnswer((_) async => throw Exception('DB error'));

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final completer = Completer<void>();
      final sub = container.listen(
        matchCandidatesProvider('event_err'),
        (_, next) {
          if (next.hasError && !completer.isCompleted) {
            completer.complete();
          }
        },
      );
      addTearDown(sub.close);
      await completer.future;

      final state = container.read(matchCandidatesProvider('event_err'));
      expect(state.hasError, isTrue);
    });
  });

  group('myMatches', () {
    test('returns matches from repository', () async {
      final matches = [
        MatchPair(
          matchId: 'match_1',
          eventId: 'event_1',
          partnerId: 'partner_1',
          matchedAt: DateTime.now(),
        ),
      ];

      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer((_) async => matches);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final result = await container.read(
        myMatchesProvider('event_1').future,
      );

      expect(result, hasLength(1));
      expect(result.first.matchId, 'match_1');
      expect(result.first.partnerId, 'partner_1');
    });

    test('returns empty list when no matches', () async {
      when(
        () => mockMatchingRepo.getMyMatches('event_none'),
      ).thenAnswer((_) async => <MatchPair>[]);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final result = await container.read(
        myMatchesProvider('event_none').future,
      );

      expect(result, isEmpty);
    });

    test('propagates error when repository throws', () async {
      when(
        () => mockMatchingRepo.getMyMatches('event_err'),
      ).thenAnswer((_) async => throw Exception('DB error'));

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final completer = Completer<void>();
      final sub = container.listen(
        myMatchesProvider('event_err'),
        (_, next) {
          if (next.hasError && !completer.isCompleted) {
            completer.complete();
          }
        },
      );
      addTearDown(sub.close);
      await completer.future;

      final state = container.read(myMatchesProvider('event_err'));
      expect(state.hasError, isTrue);
    });
  });
}
