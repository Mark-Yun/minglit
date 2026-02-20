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
    group('toggleInteraction', () {
      test('removes existing interaction and returns false', () async {
        // existing record found
        mockTable(
          mockClient,
          'social_interactions',
          maybeSingleData: {
            'id': 'interaction_1',
            'user_id': 'user_1',
            'target_id': 'party_1',
            'interaction_type': 'like',
          },
        );

        final result = await repository.toggleInteraction(
          targetId: 'party_1',
          targetType: SocialTargetType.party,
          interactionType: SocialInteractionType.like,
        );

        expect(result, isFalse);
      });

      test('creates new interaction and returns true', () async {
        // no existing record
        mockTable(
          mockClient,
          'social_interactions',
          maybeSingleData: null,
        );

        final result = await repository.toggleInteraction(
          targetId: 'party_1',
          targetType: SocialTargetType.party,
          interactionType: SocialInteractionType.like,
        );

        expect(result, isTrue);
      });

      test('throws when user not authenticated', () async {
        // Recreate without user
        mockClient = createMockSupabase();
        repository = SocialRepository(supabase: mockClient);

        expect(
          () => repository.toggleInteraction(
            targetId: 'party_1',
            targetType: SocialTargetType.party,
            interactionType: SocialInteractionType.like,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getInteractionState', () {
      test('returns true when interaction exists', () async {
        mockTable(
          mockClient,
          'social_interactions',
          maybeSingleData: {
            'id': 'interaction_1',
            'user_id': 'user_1',
            'target_id': 'party_1',
            'interaction_type': 'like',
          },
        );

        final result = await repository.getInteractionState(
          targetId: 'party_1',
          interactionType: SocialInteractionType.like,
        );

        expect(result, isTrue);
      });

      test('returns false when interaction does not exist', () async {
        mockTable(
          mockClient,
          'social_interactions',
          maybeSingleData: null,
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
        mockTable(
          mockClient,
          'social_interactions',
          selectData: [
            {'user_id': 'user_1'},
            {'user_id': 'user_2'},
            {'user_id': 'user_3'},
          ],
          countValue: 3,
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
