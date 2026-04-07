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
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>([]));

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
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>([]));

        final result = await repository.getPartiesByTag(
          'tag_1',
          limit: 10,
          offset: 0,
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
      final tag = Tag(id: 'tag_1', name: '재즈', isFeatured: true, usageCount: 5);
      final json = tag.toJson();

      expect(json['id'], 'tag_1');
      expect(json['name'], '재즈');
      expect(json['is_featured'], isTrue);
      expect(json['usage_count'], 5);
    });
  });
}
