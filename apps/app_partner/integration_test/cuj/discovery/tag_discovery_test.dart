// CUJ tests — discovery / tag-discovery (partner/search scope)
//
// 대응 spec: docs/features/discovery/tag-discovery/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/widgets/tag_selection_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

class _MockTagRepository extends Mock implements TagRepository {}

Tag _tag(String id, String name) => Tag(id: id, name: name);

Event _event(int index) => Event(
  id: 'event-$index',
  partyId: 'party-$index',
  title: '추천 이벤트 $index',
  startTime: DateTime(2026, 6, index + 1),
  endTime: DateTime(2026, 6, index + 1, 2),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockTagRepository mockTagRepo;

  setUp(() {
    mockTagRepo = _MockTagRepository();

    when(() => mockTagRepo.getFeaturedTags()).thenAnswer(
      (_) async => [
        _tag('tag-1', '소개팅'),
        _tag('tag-2', '요가'),
        _tag('tag-3', '러닝'),
        _tag('tag-4', '와인'),
        _tag('tag-5', '클럽'),
        _tag('tag-6', '루프탑'),
      ],
    );
    when(() => mockTagRepo.searchTags(any())).thenAnswer(
      (_) async => [_tag('tag-3', '러닝'), _tag('tag-7', '러닝크루')],
    );
    when(() => mockTagRepo.getTagsByIds(any())).thenAnswer((invocation) async {
      final ids = invocation.positionalArguments.first as List<String>;
      final all = <Tag>[
        _tag('tag-1', '소개팅'),
        _tag('tag-2', '요가'),
        _tag('tag-3', '러닝'),
        _tag('tag-4', '와인'),
        _tag('tag-5', '클럽'),
        _tag('tag-6', '루프탑'),
      ];
      return all.where((t) => ids.contains(t.id)).toList();
    });
    when(
      () => mockTagRepo.getTagRecommendations(),
    ).thenAnswer((_) async => [_event(1), _event(2)]);
    when(() => mockTagRepo.getUserInterestTags()).thenAnswer(
      (_) async => [_tag('tag-1', '소개팅'), _tag('tag-3', '러닝')],
    );
  });

  List<dynamic> base() => [
    tagRepositoryProvider.overrideWithValue(mockTagRepo),
  ];

  Widget sectionApp() => const Scaffold(
    body: SingleChildScrollView(
      padding: EdgeInsets.all(MinglitSpacing.medium),
      child: TagSelectionSection(),
    ),
  );

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 검색 시 태그 자동완성
  // ---------------------------------------------------------------------------
  cujGroup('2-1', '검색 시 태그 자동완성', () {
    cujCase(
      'happy: 500ms 디바운스 후 자동완성 태그 노출',
      app: sectionApp(),
      overrides: base,
      body: (t) async {
        await t.enterText(find.byType(TextField), '러닝');
        await t.pump(const Duration(milliseconds: 499));
        expect(find.text('#러닝'), findsNothing);

        await t.pump(const Duration(milliseconds: 1));
        await t.pumpAndSettle();

        expect(find.text('#러닝'), findsOneWidget);
        expect(find.text('#러닝크루'), findsOneWidget);
        verify(() => mockTagRepo.searchTags('러닝')).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: 검색어 없을 때 인기 태그 표시
  // ---------------------------------------------------------------------------
  cujGroup('2-2', '검색어 없을 때 인기 태그 표시', () {
    cujCase(
      'happy: 초기 진입 시 인기 태그 섹션 노출',
      app: sectionApp(),
      overrides: base,
      body: (t) async {
        expect(find.text('인기 태그'), findsOneWidget);
        expect(find.text('#소개팅'), findsOneWidget);
        expect(find.text('#요가'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-3: 자동완성 결과 0건
  // ---------------------------------------------------------------------------
  cujGroup('2-3', '자동완성 결과 0건', () {
    cujCase(
      'edge: 일치 태그 없음 안내 노출',
      app: sectionApp(),
      overrides: () {
        when(() => mockTagRepo.searchTags('없는태그')).thenAnswer(
          (_) async => const [],
        );
        return base();
      },
      body: (t) async {
        await t.enterText(find.byType(TextField), '없는태그');
        await t.pump(const Duration(milliseconds: 500));
        await t.pumpAndSettle();

        expect(find.text('일치하는 태그가 없어요'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 관심 태그 3개 이상 선택
  // ---------------------------------------------------------------------------
  cujGroup('3-1', '관심 태그 3개 이상 선택', () {
    cujCase(
      'happy: 3개 선택 시 선택된 태그 목록에 반영',
      app: sectionApp(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('#소개팅'));
        await t.pumpAndSettle();
        await t.tap(find.text('#요가'));
        await t.pumpAndSettle();
        await t.tap(find.text('#러닝'));
        await t.pumpAndSettle();

        expect(find.text('선택된 태그'), findsOneWidget);
        expect(find.byType(InputChip), findsNWidgets(3));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 온보딩 건너뛰기
  // ---------------------------------------------------------------------------
  cujGroup('3-2', '온보딩 건너뛰기', () {
    cujCase(
      'happy: 미선택 상태 유지 시 wizard tagIds 빈 배열',
      app: sectionApp(),
      overrides: base,
      body: (t) async {
        final container = ProviderScope.containerOf(
          t.element(find.byType(Scaffold)),
        );
        final tagIds = container
            .read(partyCreateWizardControllerProvider)
            .tagIds;

        expect(find.text('선택된 태그'), findsNothing);
        expect(tagIds, isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-3: 관심사 추천 피드 노출
  // ---------------------------------------------------------------------------
  cujGroup('3-3', '관심사 추천 피드 노출', () {
    cujCase(
      'happy: 추천 피드 provider에서 추천 이벤트 반환',
      app: const Scaffold(body: SizedBox.shrink()),
      overrides: base,
      body: (t) async {
        final container = ProviderScope.containerOf(
          t.element(find.byType(Scaffold)),
        );
        final events = await container.read(
          tagRecommendationFeedProvider.future,
        );

        expect(events, hasLength(2));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-4: 관심 태그 사후 변경
  // ---------------------------------------------------------------------------
  cujGroup('3-4', '관심 태그 사후 변경', () {
    cujCase(
      'happy: 선택 후 삭제/재선택 시 wizard tagIds 동기화',
      app: sectionApp(),
      overrides: base,
      body: (t) async {
        final container = ProviderScope.containerOf(
          t.element(find.byType(Scaffold)),
        );

        await t.tap(find.text('#소개팅'));
        await t.pumpAndSettle();
        await t.tap(find.text('#요가'));
        await t.pumpAndSettle();

        await t.tap(find.byIcon(Icons.close).first);
        await t.pumpAndSettle();
        await t.tap(find.text('#러닝'));
        await t.pumpAndSettle();

        final tagIds = container
            .read(partyCreateWizardControllerProvider)
            .tagIds;
        expect(tagIds, ['tag-2', 'tag-3']);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-1: 파트너 파티 생성 태그 선택
  // ---------------------------------------------------------------------------
  cujGroup('4-1', '파트너 파티 생성 태그 선택', () {
    cujCase(
      'happy: 인기 태그 선택 시 wizard tagIds 반영',
      app: sectionApp(),
      overrides: base,
      body: (t) async {
        final container = ProviderScope.containerOf(
          t.element(find.byType(Scaffold)),
        );

        await t.tap(find.text('#클럽'));
        await t.pumpAndSettle();

        final tagIds = container
            .read(partyCreateWizardControllerProvider)
            .tagIds;
        expect(tagIds, contains('tag-5'));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-2: 5개 초과 선택 차단
  // ---------------------------------------------------------------------------
  cujGroup('4-2', '5개 초과 선택 차단', () {
    cujCase(
      'edge: 5개 선택 후 입력 비활성 + 6번째 선택 차단',
      app: sectionApp(),
      overrides: base,
      body: (t) async {
        final container = ProviderScope.containerOf(
          t.element(find.byType(Scaffold)),
        );

        for (final label in ['#소개팅', '#요가', '#러닝', '#와인', '#클럽']) {
          await t.tap(find.text(label));
          await t.pumpAndSettle();
        }

        final textField = t.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isFalse);

        await t.tap(find.text('#루프탑'));
        await t.pumpAndSettle();

        final tagIds = container
            .read(partyCreateWizardControllerProvider)
            .tagIds;
        expect(tagIds, hasLength(5));
        expect(tagIds, isNot(contains('tag-6')));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-3: 파티 편집 시 태그 수정
  // ---------------------------------------------------------------------------
  cujGroup('4-3', '파티 편집 시 태그 수정', () {
    cujCase(
      'happy: prefill 로드 후 삭제/추가 반영',
      app: sectionApp(),
      overrides: base,
      body: (t) async {
        final container = ProviderScope.containerOf(
          t.element(find.byType(Scaffold)),
        );

        container
            .read(partyCreateWizardControllerProvider.notifier)
            .updateTagIds(['tag-1', 'tag-2']);
        await t.pumpAndSettle();

        expect(find.text('#소개팅'), findsWidgets);
        expect(find.text('#요가'), findsWidgets);

        await t.tap(find.byIcon(Icons.close).first);
        await t.pumpAndSettle();
        await t.tap(find.text('#러닝'));
        await t.pumpAndSettle();

        final tagIds = container
            .read(partyCreateWizardControllerProvider)
            .tagIds;
        expect(tagIds, ['tag-2', 'tag-3']);
      },
    );
  });
}
