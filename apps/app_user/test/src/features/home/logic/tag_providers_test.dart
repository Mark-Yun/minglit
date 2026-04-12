// Ref #1335: featuredTagsProvider / trendingTagsProvider 상태 전환 테스트
//
// 검증 포인트:
// 1. featuredTagsProvider — TagRepository.getFeaturedTags() 결과를 반환한다
// 2. trendingTagsProvider — TagRepository.getTrendingTags() 결과를 반환한다
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockTagRepository mockTagRepo;

  Tag makeTag(String name) => Tag(id: 'tag-$name', name: name);

  setUp(() {
    mockTagRepo = MockTagRepository();
  });

  group('featuredTagsProvider', () {
    test(
      'TagRepository.getFeaturedTags() 결과를 반환한다',
      () async {
        final tags = [makeTag('클럽'), makeTag('독서')];
        when(() => mockTagRepo.getFeaturedTags())
            .thenAnswer((_) async => tags);

        final container = createContainer(
          overrides: [
            tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
          ],
        );

        final result = await container.read(featuredTagsProvider.future);

        expect(result, hasLength(2));
        expect(result.first.name, '클럽');
      },
    );

    test(
      'TagRepository.getFeaturedTags() 빈 목록 — 빈 리스트 반환',
      () async {
        when(() => mockTagRepo.getFeaturedTags())
            .thenAnswer((_) async => []);

        final container = createContainer(
          overrides: [
            tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
          ],
        );

        final result = await container.read(featuredTagsProvider.future);

        expect(result, isEmpty);
      },
    );
  });

  group('trendingTagsProvider', () {
    test(
      'TagRepository.getTrendingTags() 결과를 반환한다',
      () async {
        final tags = [
          const Tag(id: 'tag-핫', name: '핫', recentCount: 42),
        ];
        when(() => mockTagRepo.getTrendingTags())
            .thenAnswer((_) async => tags);

        final container = createContainer(
          overrides: [
            tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
          ],
        );

        final result = await container.read(trendingTagsProvider.future);

        expect(result, hasLength(1));
        expect(result.first.recentCount, 42);
      },
    );

    test(
      'TagRepository.getTrendingTags() 빈 목록 — 빈 리스트 반환',
      () async {
        when(() => mockTagRepo.getTrendingTags())
            .thenAnswer((_) async => []);

        final container = createContainer(
          overrides: [
            tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
          ],
        );

        final result = await container.read(trendingTagsProvider.future);

        expect(result, isEmpty);
      },
    );
  });
}
