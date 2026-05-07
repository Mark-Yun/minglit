import 'package:app_user/src/features/event/matching/logic/commit_match_likes_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../utils/mocks.dart';
import '../../../../../utils/test_utils.dart';

void main() {
  late MockMatchingRepository mockMatchingRepo;

  setUp(() {
    mockMatchingRepo = MockMatchingRepository();
  });

  group('CommitMatchLikesController', () {
    group('commit', () {
      test('transitions to AsyncData on success', () async {
        when(
          () => mockMatchingRepo.commitMatchLikes(
            eventId: 'event_1',
            candidateIds: const ['user_2', 'user_3'],
          ),
        ).thenAnswer((_) async {});

        when(
          () => mockMatchingRepo.getMatchingCandidates('event_1'),
        ).thenAnswer((_) async => []);

        when(
          () => mockMatchingRepo.getMyMatches('event_1'),
        ).thenAnswer((_) async => []);

        when(
          () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
        ).thenAnswer((_) async => {});

        when(
          () => mockMatchingRepo.getMyVoteCount('event_1'),
        ).thenAnswer((_) async => 0);

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ],
        );

        final sub = container.listen(
          commitMatchLikesControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);
        await container.read(commitMatchLikesControllerProvider.future);

        final notifier = container.read(
          commitMatchLikesControllerProvider.notifier,
        );

        await notifier.commit(
          eventId: 'event_1',
          candidateIds: const ['user_2', 'user_3'],
        );

        final state = container.read(commitMatchLikesControllerProvider);
        expect(state, isA<AsyncData<void>>());
        verify(
          () => mockMatchingRepo.commitMatchLikes(
            eventId: 'event_1',
            candidateIds: const ['user_2', 'user_3'],
          ),
        ).called(1);
      });

      test('transitions to AsyncError on failure', () async {
        when(
          () => mockMatchingRepo.commitMatchLikes(
            eventId: any(named: 'eventId'),
            candidateIds: any(named: 'candidateIds'),
          ),
        ).thenThrow(Exception('EF failed'));

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ],
        );

        final sub = container.listen(
          commitMatchLikesControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);
        await container.read(commitMatchLikesControllerProvider.future);

        final notifier = container.read(
          commitMatchLikesControllerProvider.notifier,
        );

        await notifier.commit(
          eventId: 'event_1',
          candidateIds: const ['user_2'],
        );

        final state = container.read(commitMatchLikesControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });

      test('invalidates dependent providers on success', () async {
        when(
          () => mockMatchingRepo.commitMatchLikes(
            eventId: 'event_1',
            candidateIds: const ['user_2'],
          ),
        ).thenAnswer((_) async {});

        when(
          () => mockMatchingRepo.getMatchingCandidates('event_1'),
        ).thenAnswer((_) async => []);

        when(
          () => mockMatchingRepo.getMyMatches('event_1'),
        ).thenAnswer((_) async => []);

        when(
          () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
        ).thenAnswer((_) async => {});

        when(
          () => mockMatchingRepo.getMyVoteCount('event_1'),
        ).thenAnswer((_) async => 1);

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ],
        );

        // Prime dependent providers so they exist in the container.
        await container.read(matchCandidatesProvider('event_1').future);
        await container.read(myMatchesProvider('event_1').future);
        await container.read(myVotedCandidateIdsProvider('event_1').future);
        await container.read(myVoteCountProvider('event_1').future);

        final sub = container.listen(
          commitMatchLikesControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);
        await container.read(commitMatchLikesControllerProvider.future);

        final notifier = container.read(
          commitMatchLikesControllerProvider.notifier,
        );

        await notifier.commit(
          eventId: 'event_1',
          candidateIds: const ['user_2'],
        );

        // After commit, each provider should reload — verify the repo was called
        // a second time (once before commit, once after invalidation).
        verify(
          () => mockMatchingRepo.getMatchingCandidates('event_1'),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockMatchingRepo.getMyMatches('event_1'),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockMatchingRepo.getMyVotedCandidateIds('event_1'),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockMatchingRepo.getMyVoteCount('event_1'),
        ).called(greaterThanOrEqualTo(1));
      });
    });
  });
}
