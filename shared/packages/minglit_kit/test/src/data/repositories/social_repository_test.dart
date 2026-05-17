import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/data/repositories/social_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late SocialRepository repository;

  final mockUser = MockUser();

  void stubRpc() {
    when(
      () => mockClient.rpc<dynamic>(
        'set_social_interaction',
        params: any(named: 'params'),
      ),
    ).thenAnswer((_) => FakeRpcBuilder<dynamic>(null));
  }

  // Fix #2393: stub user-manage-social EF.
  void stubSocialEf({int status = 200}) {
    when(
      () => mockFunctions.invoke(
        'user-manage-social',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => FunctionResponse(
        status: status,
        data: jsonEncode({'success': true}),
      ),
    );
  }

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    mockFunctions = mockClient.functions as MockFunctionsClient;
    when(() => mockUser.id).thenReturn('user_1');
    repository = SocialRepository(supabase: mockClient);
  });

  group('SocialRepository', () {
    group('setInteraction', () {
      test('activates interaction without error', () async {
        stubRpc();

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
        stubRpc();

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

      // Fix #1957: mutual exclusivity and advisory lock are enforced atomically
      // inside set_social_interaction(). Verify the correct RPC params are sent.
      test('passes correct params to set_social_interaction RPC', () async {
        stubRpc();

        await repository.setInteraction(
          targetId: 'party_1',
          targetType: SocialTargetType.party,
          interactionType: SocialInteractionType.like,
          active: true,
        );

        verify(
          () => mockClient.rpc<dynamic>(
            'set_social_interaction',
            params: {
              'p_target_id': 'party_1',
              'p_target_type': 'party',
              'p_interaction_type': 'like',
              'p_active': true,
            },
          ),
        ).called(1);
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

    // Fix #2393: block/unblock/report now route through user-manage-social EF.
    group('blockPartner', () {
      test('invokes EF with block action', () async {
        stubSocialEf();

        await expectLater(
          repository.blockPartner('partner_1'),
          completes,
        );

        final captured = verify(
          () => mockFunctions.invoke(
            'user-manage-social',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'block');
        expect(body['target_id'], 'partner_1');
      });

      test('throws on EF error', () async {
        stubSocialEf(status: 500);

        expect(
          () => repository.blockPartner('partner_1'),
          throwsA(isA<FunctionException>()),
        );
      });
    });

    group('unblockPartner', () {
      test('invokes EF with unblock action', () async {
        stubSocialEf();

        await expectLater(
          repository.unblockPartner('partner_1'),
          completes,
        );

        final captured = verify(
          () => mockFunctions.invoke(
            'user-manage-social',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'unblock');
        expect(body['target_id'], 'partner_1');
      });
    });

    group('reportPartner', () {
      test('invokes EF with report action and reason', () async {
        stubSocialEf();

        await expectLater(
          repository.reportPartner(
            partnerId: 'partner_1',
            reason: 'spam',
          ),
          completes,
        );

        final captured = verify(
          () => mockFunctions.invoke(
            'user-manage-social',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'report');
        expect(body['target_id'], 'partner_1');
        expect(body['reason'], 'spam');
        expect(body.containsKey('description'), isFalse);
      });

      test('includes description when provided', () async {
        stubSocialEf();

        await repository.reportPartner(
          partnerId: 'partner_1',
          reason: 'harassment',
          description: 'Sent inappropriate messages',
        );

        final captured = verify(
          () => mockFunctions.invoke(
            'user-manage-social',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['description'], 'Sent inappropriate messages');
      });

      test('throws on EF error', () async {
        stubSocialEf(status: 400);

        expect(
          () => repository.reportPartner(
            partnerId: 'partner_1',
            reason: 'spam',
          ),
          throwsA(isA<FunctionException>()),
        );
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

        final blockedIdsBuilder = mockTable(
          mockClient,
          'social_interactions',
          selectData: [
            {'target_id': 'partner_1'},
          ],
        );
        unawaited(blockedIdsBuilder);

        final blockedPartnerIds = await repository.getBlockedPartnerIds();

        expect(blockedPartnerIds, ['partner_1']);
        // Fix #2011: regression guard — lastSelectColumns must include expected column
        expect(
          blockedIdsBuilder.lastSelectColumns,
          contains('target_id'),
          reason: 'Fix #2011: select() must include target_id',
        );

        final partnersBuilder = mockTable(
          mockClient,
          'partners',
          selectData: [
            {
              'id': 'partner_1',
              'name': '파트너',
              'profile_image_url': 'https://example.com/profile.png',
            },
          ],
        );
        final blockedIdsForPartnersBuilder = mockTable(
          mockClient,
          'social_interactions',
          selectData: [
            {'target_id': 'partner_1'},
          ],
        );
        unawaited(partnersBuilder);
        unawaited(blockedIdsForPartnersBuilder);

        final blockedPartners = await repository.getBlockedPartners();

        expect(blockedPartners, hasLength(1));
        // Fix #2011: regression guard — lastSelectColumns must include expected column
        expect(
          partnersBuilder.lastSelectColumns,
          contains('profile_image_url'),
          reason: 'Fix #2011: select() must include profile_image_url',
        );
      });
    });
  });
}
