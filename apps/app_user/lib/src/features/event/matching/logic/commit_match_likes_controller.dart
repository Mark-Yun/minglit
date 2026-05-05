import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'commit_match_likes_controller.g.dart';

@riverpod
class CommitMatchLikesController extends _$CommitMatchLikesController {
  @override
  FutureOr<void> build() {}

  Future<void> commit({
    required String eventId,
    required List<String> candidateIds,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(matchingRepositoryProvider);
      await repository.commitMatchLikes(
        eventId: eventId,
        candidateIds: candidateIds,
      );
      ref
        ..invalidate(matchCandidatesProvider(eventId))
        ..invalidate(myMatchesProvider(eventId))
        ..invalidate(myVotedCandidateIdsProvider(eventId))
        ..invalidate(myVoteCountProvider(eventId));
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
