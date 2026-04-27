import 'dart:async' show unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/data/repositories/social_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late SocialRepository repository;

  final mockUser = MockUser();

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    repository = SocialRepository(supabase: mockClient);
  });

  group('SocialRepository', () {
    group('setInteraction', () {
      test('activates interaction without error', () async {
        unawaited(mockTable(mockClient, 'social_interactions'));

        await expectLater(
          repository.setInteraction(
            targetId: 'party_1',
            targetType: SocialTargetType.party,
            interactionType: SocialInteractionType.like,
            active: true,
          ),
          completes,
        );
      });

      test('deactivates interaction without error', () async {
        unawaited(mockTable(mockClient, 'social_interactions'));

        await expectLater(
          repository.setInteraction(
            targetId: 'party_1',
            targetType: SocialTargetType.party,
            interactionType: SocialInteractionType.like,
            active: false,
          ),
          completes,
        );
      });

      test('activating like removes dislike first (mutual exclusivity)',
          () async {
        final builder = mockTable(mockClient, 'social_interactions');

        await repository.setInteraction(
          targetId: 'party_1',
          targetType: SocialTargetType.party,
          interactionType: SocialInteractionType.like,
          active: true,
        );

        // Fix #1957: verify dislike was removed before inserting like.
        expect(
          builder.recordedFilters.any(
            (f) => f.column == 'interaction_type' && f.value == 'dislike',
          ),
          isTrue,
        );
      });

      test('activating non-like/dislike skips mutual exclusivity delete',
          () async {
        final builder = mockTable(mockClient, 'social_interactions');

        await repository.setInteraction(
          targetId: 'party_1',
          targetType: SocialTargetType.party,
          interactionType: SocialInteractionType.bookmark,
          active: true,
        );

        // No delete filter for opposite types expected.
        expect(
          builder.recordedFilters.any(
            (f) =>
                f.column == 'interaction_type' &&
                (f.value == 'like' || f.value == 'dislike'),
          ),
          isFalse,
        );
      });

      test('throws when user not authenticated', () async {
        mockClient = createMockSupabase();
        repository = SocialRepository(supabase: mockClient);

        expect(
          () => repository.setInteraction(
            targetId: 'party_1',
            targetType: SocialTargetType.party,
            interactionType: SocialInteractionType.like,
            active: true,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getInteractionState', () {
      test('returns true when interaction exists', () async {
        unawaited(
          mockTable(
            mockClient,
            'social_interactions',
            maybeSingleData: {
              'id': 'interaction_1',
              'user_id': 'user_1',
              'target_id': 'party_1',
              'interaction_type': 'like',
            },
          ),
        );

        final result = await repository.getInteractionState(
          targetId: 'party_1',
          interactionType: SocialInteractionType.like,
        );

        expect(result, isTrue);
      });

      test('returns false when interaction does not exist', () async {
        unawaited(
          mockTable(
            mockClient,
            'social_interactions',
          ),
        );

        final result = await repository.getInteractionState(
          targetId: 'party_1',
          interactionType: SocialInteractionType.like,
        );

        expect(result, isFalse);
      });

      test('returns false when user not authenticated', () async {
        mockClient = createMockSupabase();
        repository = SocialRepository(supabase: mockClient);

        final result = await repository.getInteractionState(
          targetId: 'party_1',
          interactionType: SocialInteractionType.like,
        );

        expect(result, isFalse);
      });
    });

    group('getInteractionCount', () {
      test('returns count of interactions', () async {
        unawaited(
          mockTable(
            mockClient,
            'social_interactions',
            selectData: [
              {'user_id': 'user_1'},
              {'user_id': 'user_2'},
              {'user_id': 'user_3'},
            ],
            countValue: 3,
          ),
        );

        final result = await repository.getInteractionCount(
          targetId: 'party_1',
          interactionType: SocialInteractionType.like,
        );

        expect(result, 3);
      });
    });
  });
}
