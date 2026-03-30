import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'matching_vote_controller.g.dart';

@riverpod
class MatchingVoteController extends _$MatchingVoteController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> vote({
    required String eventId,
    required String candidateId,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(matchingRepositoryProvider);
      await repo.castVote(eventId: eventId, candidateId: candidateId);

      // Fix #306: 투표 후 투표 상태 + 매칭 결과 갱신
      ref
        ..invalidate(myMatchesProvider(eventId))
        ..invalidate(myVotedCandidateIdsProvider(eventId))
        ..invalidate(myVoteCountProvider(eventId));

      StatsigAnalytics.logEvent(
        MingLitEvent.matchingResult,
        metadata: {'event_id': eventId},
      );
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// Data providers (matchCandidates, myMatches, myVoteCount,
// myVotedCandidateIds, maxVoteCount) moved to minglit_kit
// matching_repository.dart to resolve cross-feature imports.
// Import them from 'package:minglit_kit/minglit_kit.dart'.
