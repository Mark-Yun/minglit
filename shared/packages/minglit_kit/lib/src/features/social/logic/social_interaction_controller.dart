import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/data/repositories/social_repository.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'social_interaction_controller.g.dart';

@riverpod
class SocialInteractionController extends _$SocialInteractionController {
  @override
  FutureOr<bool> build({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final repository = ref.watch(socialRepositoryProvider);
    return repository.getInteractionState(
      targetId: targetId,
      interactionType: interactionType,
    );
  }

  Future<void> toggle() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final currentIsActive = state.asData?.value;
    if (currentIsActive == null) return;

    final repository = ref.read(socialRepositoryProvider);

    final newIsActive = !currentIsActive;
    state = AsyncData(newIsActive);

    try {
      final actualIsActive = await repository.toggleInteraction(
        targetId: targetId,
        targetType: targetType,
        interactionType: interactionType,
      );

      if (actualIsActive != newIsActive) {
        ref.invalidateSelf();
      }
    } on Object catch (e, st) {
      Log.e('❌ [SocialController] Toggle Failed', e, st);
      state = AsyncData(currentIsActive);
      state = AsyncError(e, st);
    }
  }
}
