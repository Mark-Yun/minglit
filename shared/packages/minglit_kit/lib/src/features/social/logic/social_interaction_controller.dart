import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/social_repository.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'social_interaction_controller.g.dart';

@riverpod
/// Manages the state of a single social interaction
/// (like, subscribe, bookmark, block).
class SocialInteractionController extends _$SocialInteractionController {
  @override
  FutureOr<bool> build({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) async {
    // P0-0c: use currentUserProvider so build() re-runs on auth changes.
    final user = ref.watch(currentUserProvider);
    if (user == null) return false;

    final repository = ref.watch(socialRepositoryProvider);
    return repository.getInteractionState(
      targetId: targetId,
      interactionType: interactionType,
    );
  }

  /// Toggles the interaction state optimistically.
  Future<void> toggle() async {
    // P0-0c: one-shot read — no rebuild needed in a mutating method.
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final currentIsActive = state.asData?.value;
    if (currentIsActive == null) return;

    final repository = ref.read(socialRepositoryProvider);

    final newIsActive = !currentIsActive;
    state = AsyncData(newIsActive);

    try {
      await repository.setInteraction(
        targetId: targetId,
        targetType: targetType,
        interactionType: interactionType,
        active: newIsActive,
      );
    } on Object catch (e, st) {
      Log.e('❌ [SocialController] Toggle Failed', e, st);
      state = AsyncData(currentIsActive);
      state = AsyncError(e, st);
    }
  }
}
