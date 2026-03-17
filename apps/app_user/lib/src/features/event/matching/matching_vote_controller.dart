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

      // Refresh candidates (to update UI if needed, though mostly static)
      // and refresh matches to see if a match occurred instantly
      ref.invalidate(myMatchesProvider(eventId));

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

@riverpod
Future<List<UserProfile>> matchCandidates(Ref ref, String eventId) {
  return ref.watch(matchingRepositoryProvider).getMatchingCandidates(eventId);
}

@riverpod
Future<List<MatchPair>> myMatches(Ref ref, String eventId) {
  return ref.watch(matchingRepositoryProvider).getMyMatches(eventId);
}
