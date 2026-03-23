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
      ref.invalidate(myMatchesProvider(eventId));
      ref.invalidate(myVotedCandidateIdsProvider(eventId));
      ref.invalidate(myVoteCountProvider(eventId));

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

// Fix #306: 잔여 투표 수 표시 + 투표 완료 후보 비활성화
@riverpod
Future<int> myVoteCount(Ref ref, String eventId) {
  return ref.watch(matchingRepositoryProvider).getMyVoteCount(eventId);
}

@riverpod
Future<Set<String>> myVotedCandidateIds(Ref ref, String eventId) {
  return ref.watch(matchingRepositoryProvider).getMyVotedCandidateIds(eventId);
}

@riverpod
Future<int> maxVoteCount(Ref ref, String eventId) async {
  final rules = await ref
      .watch(matchingRepositoryProvider)
      .getMatchRules(eventId);
  if (rules.isEmpty) return 1;
  return rules.map((r) => r.voteCount).reduce((a, b) => a > b ? a : b);
}
