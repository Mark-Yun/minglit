// Ref #1335: FeaturedTagChipBar widget 테스트
//
// 검증 포인트:
// 1. 빈 태그 목록 → SizedBox.shrink (아무것도 렌더링 안 됨)
// 2. 태그 목록 → #tagName 칩 렌더링
// 3. 에러 상태 → SizedBox.shrink
// 4. 칩 탭 → TagCoordinator.goToTagEventList() 호출
import 'package:app_user/src/features/home/widgets/featured_tag_chip_bar.dart';
import 'package:app_user/src/logic/tag_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

// Fix #1335: TagCoordinator는 GoRouter를 필요로 하므로,
// implements로 호출 기록만 수행하는 fake를 정의한다.
class _FakeTagCoordinator implements TagCoordinator {
  final List<(String tagId, String tagName)> calls = [];

  @override
  void goToTagEventList(String tagId, String tagName) =>
      calls.add((tagId, tagName));
}

void main() {
  late MockTagRepository mockTagRepo;
  late _FakeTagCoordinator fakeCoordinator;

  Tag makeTag(String name) => Tag(id: 'tag-$name', name: name);

  Widget buildSubject({
    required void Function() stub,
  }) {
    stub();
    return ProviderScope(
      overrides: [
        tagRepositoryProvider.overrideWithValue(mockTagRepo),
        tagCoordinatorProvider.overrideWithValue(fakeCoordinator),
      ],
      child: const MaterialApp(
        home: Scaffold(body: FeaturedTagChipBar()),
      ),
    );
  }

  setUp(() {
    mockTagRepo = MockTagRepository();
    fakeCoordinator = _FakeTagCoordinator();
  });

  group('FeaturedTagChipBar', () {
    testWidgets(
      '빈 태그 목록 — 아무것도 렌더링하지 않는다',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            stub: () => when(
              () => mockTagRepo.getFeaturedTags(),
            ).thenAnswer((_) async => []),
          ),
        );
        await tester.pump();

        expect(find.byType(ListView), findsNothing);
      },
    );

    testWidgets(
      '태그 목록 — #tagName 칩이 렌더링된다',
      (tester) async {
        final tags = [makeTag('클럽'), makeTag('영화')];
        await tester.pumpWidget(
          buildSubject(
            stub: () => when(
              () => mockTagRepo.getFeaturedTags(),
            ).thenAnswer((_) async => tags),
          ),
        );
        await tester.pump();

        expect(find.text('#클럽'), findsOneWidget);
        expect(find.text('#영화'), findsOneWidget);
      },
    );

    testWidgets(
      '에러 상태 — 아무것도 렌더링하지 않는다',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            stub: () => when(
              () => mockTagRepo.getFeaturedTags(),
            ).thenThrow(Exception('network error')),
          ),
        );
        await tester.pump();

        expect(find.byType(ListView), findsNothing);
      },
    );

    testWidgets(
      '칩 탭 — TagCoordinator.goToTagEventList()가 올바른 tagId/tagName으로 호출된다',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            stub: () => when(
              () => mockTagRepo.getFeaturedTags(),
            ).thenAnswer((_) async => [makeTag('클럽')]),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('#클럽'));
        await tester.pump();

        expect(fakeCoordinator.calls, hasLength(1));
        expect(fakeCoordinator.calls.first.$1, 'tag-클럽');
        expect(fakeCoordinator.calls.first.$2, '클럽');
      },
    );
  });
}
