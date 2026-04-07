// Fix #1136: TagSelectionSection 위젯 테스트
//
// - 인기 태그 렌더링 검증
// - 태그 선택/해제 동작 검증
// - 5개 초과 선택 비활성화 검증
// - 검색 필드 렌더링 검증
import 'package:app_partner/src/features/party/create/logic/tag_selection_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/widgets/tag_selection_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockTagRepository extends Mock implements TagRepository {}

Tag _makeTag(String name, {bool isFeatured = true}) {
  return Tag(id: 'tag-$name', name: name, isFeatured: isFeatured);
}

final List<Tag> _featuredTags = [
  _makeTag('소개팅'),
  _makeTag('미팅'),
  _makeTag('네트워킹'),
  _makeTag('운동'),
  _makeTag('러닝'),
];

Widget _buildWidget({
  List<Tag>? initialTags,
  List<Tag>? featuredTags,
  _MockTagRepository? mockRepo,
}) {
  final repo = mockRepo ?? _MockTagRepository();
  when(repo.getFeaturedTags).thenAnswer(
    (_) async => featuredTags ?? _featuredTags,
  );
  when(() => repo.getTagsByIds(any())).thenAnswer((invocation) async {
    final ids = invocation.positionalArguments.first as List<String>;
    final allTags = [
      ...(featuredTags ?? _featuredTags),
      ...(initialTags ?? []),
    ];
    return allTags.where((t) => ids.contains(t.id)).toList();
  });
  when(() => repo.getTagsByPartyId(any())).thenAnswer(
    (_) async => initialTags ?? [],
  );
  when(() => repo.searchTags(any())).thenAnswer((_) async => []);

  return ProviderScope(
    overrides: [
      tagRepositoryProvider.overrideWithValue(repo),
      // wizard state — 초기 태그 없음
      partyCreateWizardControllerProvider.overrideWith(
        () => _FakeWizardController(
          tagIds: initialTags?.map((t) => t.id).toList() ?? [],
        ),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: TagSelectionSection(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('TagSelectionSection', () {
    testWidgets('섹션 헤더 "태그 (최대 5개)"가 표시된다', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('태그 (최대 5개)'), findsOneWidget);
    });

    testWidgets('태그 검색 입력 필드가 표시된다', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('태그 검색...'), findsOneWidget);
    });

    testWidgets('인기 태그 퀵 선택이 표시된다', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('인기 태그'), findsOneWidget);
      for (final tag in _featuredTags) {
        expect(find.text('#${tag.name}'), findsOneWidget);
      }
    });

    testWidgets('인기 태그 탭 시 선택된 태그에 추가된다', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('#소개팅'));
      await tester.pumpAndSettle();

      // 선택된 태그 섹션이 나타난다
      expect(find.text('선택된 태그'), findsOneWidget);
    });

    testWidgets('선택된 태그 InputChip에 삭제 아이콘이 있다', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pumpAndSettle();

      // 소개팅 태그 선택
      await tester.tap(find.text('#소개팅'));
      await tester.pumpAndSettle();

      // InputChip의 삭제 버튼 (close icon) 확인
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('선택된 태그 삭제 시 목록에서 제거된다', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pumpAndSettle();

      // 소개팅 태그 선택
      await tester.tap(find.text('#소개팅'));
      await tester.pumpAndSettle();

      expect(find.text('선택된 태그'), findsOneWidget);

      // 삭제 아이콘 탭
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 선택된 태그 섹션이 사라진다
      expect(find.text('선택된 태그'), findsNothing);
    });

    testWidgets('태그 5개 선택 시 검색 필드가 비활성화된다', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pumpAndSettle();

      // 5개 태그 선택
      for (final tag in _featuredTags) {
        await tester.tap(find.text('#${tag.name}'));
        await tester.pumpAndSettle();
      }

      // 검색 필드 비활성화 확인
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('태그 5개 초과 선택이 불가하다', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pumpAndSettle();

      // 5개 태그 선택
      for (final tag in _featuredTags) {
        await tester.tap(find.text('#${tag.name}'));
        await tester.pumpAndSettle();
      }

      // TagSelectionController 상태 직접 확인
      // — 이미 5개가 선택되어 있으므로 isMaxReached = true
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TagSelectionSection)),
      );
      final controller = container.read(
        tagSelectionControllerProvider.notifier,
      );
      expect(controller.isMaxReached, isTrue);
      expect(container.read(tagSelectionControllerProvider).length, 5);
    });

    testWidgets('태그 없이도 크래시 없이 렌더링된다', (tester) async {
      final repo = _MockTagRepository();
      when(repo.getFeaturedTags).thenAnswer((_) async => []);
      when(() => repo.getTagsByIds(any())).thenAnswer((_) async => []);
      when(() => repo.getTagsByPartyId(any())).thenAnswer((_) async => []);
      when(() => repo.searchTags(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(_buildWidget(featuredTags: [], mockRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(TagSelectionSection), findsOneWidget);
    });
  });

  group('TagSelectionController', () {
    ProviderContainer makeContainer() {
      return ProviderContainer();
    }

    test('초기 상태는 빈 목록이다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(tagSelectionControllerProvider), isEmpty);
    });

    test('addTag가 태그를 추가한다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final tag = _makeTag('소개팅');
      container.read(tagSelectionControllerProvider.notifier).addTag(tag);

      expect(container.read(tagSelectionControllerProvider), hasLength(1));
      expect(
        container.read(tagSelectionControllerProvider).first.id,
        'tag-소개팅',
      );
    });

    test('동일 태그 중복 추가가 무시된다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final tag = _makeTag('소개팅');
      container.read(tagSelectionControllerProvider.notifier).addTag(tag);
      container.read(tagSelectionControllerProvider.notifier).addTag(tag);

      expect(container.read(tagSelectionControllerProvider), hasLength(1));
    });

    test('5개 초과 추가가 무시된다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tagSelectionControllerProvider.notifier);
      for (var i = 0; i < 6; i++) {
        notifier.addTag(_makeTag('tag$i'));
      }

      expect(container.read(tagSelectionControllerProvider), hasLength(5));
    });

    test('removeTag가 태그를 제거한다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final tag = _makeTag('소개팅');
      final notifier = container.read(tagSelectionControllerProvider.notifier);
      notifier.addTag(tag);
      notifier.removeTag('tag-소개팅');

      expect(container.read(tagSelectionControllerProvider), isEmpty);
    });

    test('clearTags가 모든 태그를 제거한다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tagSelectionControllerProvider.notifier);
      notifier.addTag(_makeTag('소개팅'));
      notifier.addTag(_makeTag('미팅'));
      notifier.clearTags();

      expect(container.read(tagSelectionControllerProvider), isEmpty);
    });

    test('setTags가 태그 목록을 교체한다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tagSelectionControllerProvider.notifier);
      notifier.addTag(_makeTag('소개팅'));

      final newTags = [_makeTag('미팅'), _makeTag('네트워킹')];
      notifier.setTags(newTags);

      expect(container.read(tagSelectionControllerProvider), hasLength(2));
      expect(
        container.read(tagSelectionControllerProvider).map((t) => t.name),
        containsAll(['미팅', '네트워킹']),
      );
    });

    test('setTags가 6개 이상이면 5개로 잘린다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tagSelectionControllerProvider.notifier);
      final tags = List.generate(6, (i) => _makeTag('tag$i'));
      notifier.setTags(tags);

      expect(container.read(tagSelectionControllerProvider), hasLength(5));
    });

    test('isMaxReached는 5개 도달 시 true를 반환한다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tagSelectionControllerProvider.notifier);
      expect(notifier.isMaxReached, isFalse);

      for (var i = 0; i < 5; i++) {
        notifier.addTag(_makeTag('tag$i'));
      }

      expect(notifier.isMaxReached, isTrue);
    });

    test('tagIds는 선택된 태그의 id 목록을 반환한다', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tagSelectionControllerProvider.notifier);
      notifier.addTag(_makeTag('소개팅'));
      notifier.addTag(_makeTag('미팅'));

      expect(notifier.tagIds, containsAll(['tag-소개팅', 'tag-미팅']));
    });
  });
}

class _FakeWizardController extends PartyCreateWizardController {
  _FakeWizardController({required this.tagIds});
  final List<String> tagIds;

  @override
  PartyCreateWizardState build() => PartyCreateWizardState(tagIds: tagIds);
}
