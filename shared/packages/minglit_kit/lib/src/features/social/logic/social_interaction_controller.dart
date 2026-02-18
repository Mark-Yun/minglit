import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/data/repositories/social_repository.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'social_interaction_controller.freezed.dart';
part 'social_interaction_controller.g.dart';

/// Represents a social interaction state and count.
@freezed
abstract class InteractionState with _$InteractionState {
  /// Creates an interaction state.
  const factory InteractionState({
    /// Whether the current user has the interaction active.
    required bool isActive,

    /// Total count for this interaction type.
    required int count,
  }) = _InteractionState;
}

/// Manages social interaction state for a target.
@riverpod
class SocialInteractionController extends _$SocialInteractionController {
  /// Loads the interaction state for the given target and type.
  @override
  FutureOr<InteractionState> build({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) async {
    final repository = ref.watch(socialRepositoryProvider);

    final results = await Future.wait([
      repository.getInteractionState(
        targetId: targetId,
        interactionType: interactionType,
      ),
      repository.getInteractionCount(
        targetId: targetId,
        interactionType: interactionType,
      ),
    ]);

    return InteractionState(
      isActive: results[0] as bool,
      count: results[1] as int,
    );
  }

  /// Toggles the interaction optimistically.
  Future<void> toggle() async {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    final repository = ref.read(socialRepositoryProvider);

    // 1. Optimistic Update
    final newIsActive = !currentState.isActive;
    final newCount = newIsActive
        ? currentState.count + 1
        : currentState.count - 1;

    state = AsyncData(
      currentState.copyWith(
        isActive: newIsActive,
        count: newCount < 0 ? 0 : newCount,
      ),
    );

    try {
      // 2. Server Request
      final actualIsActive = await repository.toggleInteraction(
        targetId: targetId,
        targetType: targetType,
        interactionType: interactionType,
      );

      // 3. Sync with actual result (if different from optimistic)
      if (actualIsActive != newIsActive) {
        ref.invalidateSelf();
      }
    } on Object catch (e, st) {
      // 4. Rollback on error
      Log.e('❌ [SocialController] Toggle Failed', e, st);
      state = AsyncData(currentState);
      // Optional: Propagate error to UI
      state = AsyncError(e, st);
    }
  }
}
