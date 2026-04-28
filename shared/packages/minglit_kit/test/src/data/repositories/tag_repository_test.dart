import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/tag.dart';
import 'package:minglit_kit/src/data/repositories/tag_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late TagRepository repository;

  final tagJson1 = {
    'id': 'tag_1',
    'name': '재즈',
    'is_featured': true,
    'usage_count': 42,
  };
  final tagJson2 = {
    'id': 'tag_2',
    'name': '루프탑',
    'is_featured': false,
    'usage_count': 17,
  };

  setUp(() {
    mockClient = createMockSupabase();
    repository = TagRepository(supabase: mockClient);
  });

  group('TagRepository', () {
    group('getFeaturedTags', () {
      test('returns list of featured tags', () async {
        when(
          () => mockClient.rpc<dynamic>('get_featured_tags'),
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>([tagJson1, tagJson2]));

        final result = await repository.getFeaturedTags();

        expect(result, hasLength(2));
        expect(result.first.id, 'tag_1');
        expect(result.first.name, '재즈');
        expect(result.first.isFeatured, isTrue);
        expect(result.first.usageCount, 42);
      });

      test('returns empty list when no featured tags', () async {
        when(
          () => mockClient.rpc<dynamic>('get_featured_tags'),
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>(<dynamic>[]));

        final result = await repository.getFeaturedTags();

        expect(result, isEmpty);
      });

      test('rethrows exception on network failure', () async {
        when(
          () => mockClient.rpc<dynamic>('get_featured_tags'),
        ).thenThrow(Exception('Network error'));

        expect(
          () => repository.getFeaturedTags(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getTrendingTags', () {
      test('calls RPC with correct params and returns tags', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_trending_tags',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>([tagJson1]));

        final result = await repository.getTrendingTags(limit: 5, days: 3);

        expect(result, hasLength(1));
        expect(result.first.name, '재즈');
      });
    });

    group('searchTags', () {
      test('returns matching tags for query', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'search_tags',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>([tagJson2]));

        final result = await repository.searchTags('루프');

        expect(result, hasLength(1));
        expect(result.first.name, '루프탑');
      });
    });

    group('getPartiesByTag', () {
      test('calls RPC with tagId, limit, and offset', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_parties_by_tag',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>(<dynamic>[]));

        final result = await repository.getPartiesByTag(
          'tag_1',
        );

        expect(result, isEmpty);
      });
    });

    group('upsertUserInterestTags', () {
      test('calls RPC without error', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'upsert_user_interest_tags',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>(null));

        await expectLater(
          () => repository.upsertUserInterestTags(['tag_1', 'tag_2']),
          returnsNormally,
        );
      });
    });

    // Fix #1136: getUserInterestTags은 비로그인 상태에서 빈 목록을 반환해야 한다
    group('getUserInterestTags', () {
      test('returns empty list when user is not authenticated', () async {
        // createMockSupabase with no currentUser → auth.currentUser == null
        final unauthClient = createMockSupabase();
        final unauthRepo = TagRepository(supabase: unauthClient);

        final result = await unauthRepo.getUserInterestTags();

        expect(result, isEmpty);
        // from('user_interest_tags') should never be called
        verifyNever(() => unauthClient.from('user_interest_tags'));

        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user_1');
        final authedClient = createMockSupabase(currentUser: mockUser);
        final authedRepo = TagRepository(supabase: authedClient);

        final interestTagsBuilder = mockTable(
          authedClient,
          'user_interest_tags',
          selectData: [
            {
              'tag_id': 'tag_1',
              'tags': tagJson1,
            },
          ],
        );
        unawaited(interestTagsBuilder);

        final interestTags = await authedRepo.getUserInterestTags();

        expect(interestTags, hasLength(1));
        expect(interestTags.first.id, 'tag_1');
        // Fix #2011: regression guard — lastSelectColumns must include expected column
        expect(
          interestTagsBuilder.lastSelectColumns,
          contains('tag_id'),
          reason: 'Fix #2011: select() must include tag_id',
        );

        final partyTagsBuilder = mockTable(
          authedClient,
          'party_tags',
          selectData: [
            {'tags': tagJson2},
          ],
        );
        unawaited(partyTagsBuilder);

        final partyTags = await authedRepo.getTagsByPartyId('party_1');

        expect(partyTags, hasLength(1));
        expect(partyTags.first.id, 'tag_2');
        // Fix #2011: regression guard — lastSelectColumns must include expected column
        expect(
          partyTagsBuilder.lastSelectColumns,
          contains('tags(*)'),
          reason: 'Fix #2011: select() must include tags(*)',
        );
      });
    });
  });

  group('Tag model', () {
    test('fromJson correctly maps snake_case fields', () {
      final tag = Tag.fromJson(tagJson1);

      expect(tag.id, 'tag_1');
      expect(tag.name, '재즈');
      expect(tag.isFeatured, isTrue);
      expect(tag.usageCount, 42);
    });

    test('default values applied when optional fields absent', () {
      final tag = Tag.fromJson({'id': 'tag_x', 'name': '테스트'});

      expect(tag.isFeatured, isFalse);
      expect(tag.usageCount, 0);
    });

    test('toJson excludes no required fields', () {
      const tag = Tag(id: 'tag_1', name: '재즈', isFeatured: true, usageCount: 5);
      final json = tag.toJson();

      expect(json['id'], 'tag_1');
      expect(json['name'], '재즈');
      expect(json['is_featured'], isTrue);
      expect(json['usage_count'], 5);
    });

    // Fix #1224: TrendingTagSection — recent_count 역직렬화 회귀 테스트
    test('fromJson maps recent_count to recentCount', () {
      final tag = Tag.fromJson({
        'id': '1',
        'name': 'test',
        'recent_count': 42,
      });

      expect(tag.recentCount, 42);
    });

    test('recentCount defaults to 0 when recent_count absent', () {
      final tag = Tag.fromJson({'id': '1', 'name': 'test'});

      expect(tag.recentCount, 0);
    });
  });
}
