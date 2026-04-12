import 'package:app_user/src/features/home/widgets/trending_tag_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  late MockTagRepository mockTagRepo;

  Tag makeTag({
    required String name,
    required int recentCount,
  }) =>
      Tag(
        id: 'tag-$name',
        name: name,
        recentCount: recentCount,
      );

  Widget buildSubject({
    required List<Tag> tags,
  }) {
    when(() => mockTagRepo.getTrendingTags()).thenAnswer((_) async => tags);
    return ProviderScope(
      overrides: [
        tagRepositoryProvider.overrideWithValue(mockTagRepo),
      ],
      child: const MaterialApp(home: Scaffold(body: TrendingTagSection())),
    );
  }

  setUp(() {
    mockTagRepo = MockTagRepository();
  });

  group('TrendingTagSection', () {
    // Fix #1286 regression: recentCount가 0인 태그는 핫 태그 섹션에서 숨겨야 한다.
    testWidgets(
      'hides section entirely when all tags have recentCount == 0',
      (tester) async {
        final tags = [
          makeTag(name: '독서', recentCount: 0),
          makeTag(name: '스터디', recentCount: 0),
        ];

        await tester.pumpWidget(buildSubject(tags: tags));
        await tester.pump(); // let async provider resolve

        expect(find.text('🔥 핫 태그'), findsNothing);
        expect(find.text('#독서'), findsNothing);
      },
    );

    testWidgets(
      'shows only tags with recentCount > 0',
      (tester) async {
        final tags = [
          makeTag(name: '독서', recentCount: 5),
          makeTag(name: '스터디', recentCount: 0),
          makeTag(name: '영화', recentCount: 3),
        ];

        await tester.pumpWidget(buildSubject(tags: tags));
        await tester.pump();

        expect(find.text('🔥 핫 태그'), findsOneWidget);
        expect(find.text('#독서'), findsOneWidget);
        expect(find.text('#영화'), findsOneWidget);
        // 스터디는 recentCount=0이므로 숨겨져야 함
        expect(find.text('#스터디'), findsNothing);
      },
    );

    testWidgets(
      'hides section when tag list is empty',
      (tester) async {
        await tester.pumpWidget(buildSubject(tags: []));
        await tester.pump();

        expect(find.text('🔥 핫 태그'), findsNothing);
      },
    );

    testWidgets(
      'renders 7일 +N label for active tags',
      (tester) async {
        final tags = [makeTag(name: '클럽', recentCount: 42)];

        await tester.pumpWidget(buildSubject(tags: tags));
        await tester.pump();

        expect(find.text('7일 +42'), findsOneWidget);
      },
    );
  });
}
