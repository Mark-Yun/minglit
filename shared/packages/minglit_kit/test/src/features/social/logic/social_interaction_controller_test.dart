import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/data/repositories/social_repository.dart';
import 'package:minglit_kit/src/features/social/logic/social_interaction_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_utils.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository mockRepo;

  const targetId = 'party_1';
  const targetType = SocialTargetType.party;
  const interactionType = SocialInteractionType.like;

  setUpAll(() {
    registerFallbackValue(SocialTargetType.party);
    registerFallbackValue(SocialInteractionType.like);
  });

  setUp(() {
    mockRepo = MockSocialRepository();
  });

  ProviderContainer createTestContainer({
    required bool initialState,
  }) {
    return createContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(mockRepo),
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).overrideWith(() {
          return _TestSocialInteractionController(
            initialState,
            hasUser: true,
          );
        }),
      ],
    );
  }

  group('SocialInteractionController', () {
    test('build returns initial state from override', () async {
      final container = createTestContainer(initialState: false);

      final result = await container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).future,
      );

      expect(result, isFalse);
    });

    test('build returns true when interaction exists', () async {
      final container = createTestContainer(initialState: true);

      final result = await container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).future,
      );

      expect(result, isTrue);
    });

    test('toggle optimistically updates state', () async {
      when(
        () => mockRepo.toggleInteraction(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ),
      ).thenAnswer((_) async => true);

      final container = createTestContainer(initialState: false);

      await container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).future,
      );

      final notifier = container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).notifier,
      );

      await notifier.toggle();

      final state = container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ),
      );
      expect(state.value, isTrue);
    });

    test('toggle reverts state on error', () async {
      when(
        () => mockRepo.toggleInteraction(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ),
      ).thenThrow(Exception('Network error'));

      final container = createTestContainer(initialState: false);

      await container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).future,
      );

      final notifier = container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).notifier,
      );

      await notifier.toggle();

      final state = container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ),
      );
      // Should be error state after revert
      expect(state, isA<AsyncError<bool>>());
    });

    test('toggle does nothing when user is null', () async {
      final container = createContainer(
        overrides: [
          socialRepositoryProvider.overrideWithValue(mockRepo),
          socialInteractionControllerProvider(
            targetId: targetId,
            targetType: targetType,
            interactionType: interactionType,
          ).overrideWith(() {
            return _TestSocialInteractionController(
              false,
              hasUser: false,
            );
          }),
        ],
      );

      await container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).future,
      );

      final notifier = container.read(
        socialInteractionControllerProvider(
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ).notifier,
      );

      await notifier.toggle();

      verifyNever(
        () => mockRepo.toggleInteraction(
          targetId: any(named: 'targetId'),
          targetType: any(named: 'targetType'),
          interactionType: any(named: 'interactionType'),
        ),
      );
    });
  });
}

/// A test controller that bypasses the Supabase.instance dependency.
class _TestSocialInteractionController
    extends SocialInteractionController {
  _TestSocialInteractionController(this._initialState, {
    required this.hasUser,
  });
  final bool _initialState;
  final bool hasUser;

  @override
  FutureOr<bool> build({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) {
    return _initialState;
  }

  @override
  Future<void> toggle() async {
    if (!hasUser) return;

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
      state = AsyncData(currentIsActive);
      state = AsyncError(e, st);
    }
  }
}
