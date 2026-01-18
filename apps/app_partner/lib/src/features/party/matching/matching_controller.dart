import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'matching_controller.g.dart';

@riverpod
class MatchingController extends _$MatchingController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> updateRules({
    required String eventId,
    required List<Map<String, String>> rules,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(matchingRepositoryProvider);
      await repo.updateMatchRules(eventId: eventId, rules: rules);
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}


@riverpod
Future<List<MatchRule>> eventMatchRules(Ref ref, String eventId) {
  return ref.watch(matchingRepositoryProvider).getMatchRules(eventId);
}