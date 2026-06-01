// CUJ tests — discovery / tag-discovery
//
// 대응 spec: docs/features/discovery/tag-discovery/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// Fix #2561: discovery 카테고리 CUJ integration test 전무 해소 (tag-discovery)

import 'package:app_user/src/features/home/logic/selected_tags_provider.dart';
import 'package:app_user/src/features/home/widgets/featured_tag_chip_bar.dart';
import 'package:app_user/src/features/home/widgets/trending_tag_section.dart';
import 'package:app_user/src/features/tag/ui/tag_event_list_page.dart';
import 'package:app_user/src/logic/tag_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

class _FakeTagCoordinator implements TagCoordinator {
  final List<(String tagId, String tagName)> calls = [];

  @override
  void goToTagEventList(String tagId, String tagName) =>
      calls.add((tagId, tagName));
}

class _MockTagRepository extends Mock implements TagRepository {}

Tag _makeTag(String name) => Tag(id: 'tag-$name', name: name);

Event _makeEvent(int index) => Event(
  id: 'event-$index',
  partyId: 'party-$index',
  title: 'Test Event $index',
  startTime: DateTime(2026, 5, index + 1),
  endTime: DateTime(2026, 5, index + 1, 2),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Event _makeEventWithTags(List<Tag> tags) => Event(
  id: 'event-tags',
  partyId: 'party-tags',
  title: '태그 이벤트',
  startTime: DateTime(2026, 6),
  endTime: DateTime(2026, 6, 1, 2),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  party: Party(
    id: 'party-tags',
    partnerId: 'partner-1',
    title: '태그 파티',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    tags: tags,
  ),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late _MockTagRepository mockTagRepo;
  late _FakeTagCoordinator fakeCoordinator;
  late List<String> tappedCardTags;

  setUp(() {
    mockTagRepo = _MockTagRepository();
    fakeCoordinator = _FakeTagCoordinator();
    tappedCardTags = <String>[];
    // Default stubs — 반드시 pumpWidget 전에 등록되어야 함 (setUp에서 설정)
    when(() => mockTagRepo.getFeaturedTags()).thenAnswer(
      (_) async => [_makeTag('클럽'), _makeTag('요가')],
    );
    when(
      () => mockTagRepo.getPartiesByTag(
        any(),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => [_makeEvent(1), _makeEvent(2)]);
    when(() => mockTagRepo.getTrendingTags()).thenAnswer(
      (_) async => [const Tag(id: 'tag-run', name: '러닝', recentCount: 12)],
    );
  });

  List<dynamic> base() => [
    tagRepositoryProvider.overrideWithValue(mockTagRepo),
    tagCoordinatorProvider.overrideWithValue(fakeCoordinator),
  ];

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 홈 인기 태그 칩 탭 → 태그 페이지 이동 (FR-1, FR-2)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '홈 인기 태그 칩 탭 → 태그 페이지 이동', () {
    cujCase(
      'happy: 태그 칩 탭 → coordinator.goToTagEventList 호출',
      app: const Scaffold(body: FeaturedTagChipBar()),
      overrides: base,
      body: (t) async {
        // FeaturedTagChipBar는 태그를 '#tagName' 형식으로 렌더링
        expect(find.text('#클럽'), findsOneWidget);

        await t.tap(find.text('#클럽'));
        await t.pumpAndSettle();

        expect(fakeCoordinator.calls, hasLength(1));
        expect(fakeCoordinator.calls.first.$2, '클럽');
      },
    );

    cujCase(
      'edge: 인기 태그 0건 → 칩바 숨김',
      app: const Scaffold(body: FeaturedTagChipBar()),
      overrides: () {
        // edge case: 빈 목록 — overrides()는 pumpWidget 전 실행되므로 stub 덮어씀
        when(() => mockTagRepo.getFeaturedTags()).thenAnswer((_) async => []);
        return base();
      },
      body: (t) async {
        expect(find.byType(FilterChip), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 인기 태그 다중 선택 OR 필터 (FR-2)
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '인기 태그 다중 선택 OR 필터', () {
    cujCase(
      'happy: 인기 태그 2개 연속 탭 → 선택 상태/선택 집합 갱신',
      app: Scaffold(
        body: Column(
          children: [
            const FeaturedTagChipBar(),
            Consumer(
              builder: (context, ref, _) {
                final selectedIds = ref.watch(selectedTagsProvider).toList()
                  ..sort();
                return Text('selected:${selectedIds.join(",")}');
              },
            ),
          ],
        ),
      ),
      overrides: () {
        when(() => mockTagRepo.getFeaturedTags()).thenAnswer(
          (_) async => [_makeTag('클럽'), _makeTag('요가'), _makeTag('러닝')],
        );
        return base();
      },
      body: (t) async {
        await t.tap(find.text('#클럽'));
        await t.pumpAndSettle();
        await t.tap(find.text('#요가'));
        await t.pumpAndSettle();

        expect(fakeCoordinator.calls, hasLength(2));
        expect(fakeCoordinator.calls[0].$2, '클럽');
        expect(fakeCoordinator.calls[1].$2, '요가');
        expect(find.byIcon(Icons.check), findsNWidgets(2));
        expect(find.text('selected:tag-요가,tag-클럽'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 핫 태그 섹션 탐색 (FR-3)
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '핫 태그 섹션 탐색', () {
    cujCase(
      'happy: 핫 태그 카드 노출 + 탭 시 태그 페이지 이동',
      app: const Scaffold(body: TrendingTagSection()),
      overrides: base,
      body: (t) async {
        expect(find.text('🔥 핫 태그'), findsOneWidget);
        expect(find.text('#러닝'), findsOneWidget);
        expect(find.text('7일 +12'), findsOneWidget);

        await t.tap(find.text('#러닝'));
        await t.pumpAndSettle();

        expect(fakeCoordinator.calls, hasLength(1));
        expect(fakeCoordinator.calls.first.$2, '러닝');
      },
    );

    cujCase(
      'edge: recentCount=0 태그만 있으면 섹션 숨김',
      app: const Scaffold(body: TrendingTagSection()),
      overrides: () {
        when(() => mockTagRepo.getTrendingTags()).thenAnswer(
          (_) async => [const Tag(id: 'tag-zero', name: '정적')],
        );
        return base();
      },
      body: (t) async {
        expect(find.text('🔥 핫 태그'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-4: 이벤트 카드 태그 뱃지 탭/표시 (FR-4)
  // ---------------------------------------------------------------------------

  cujGroup('1-4', '이벤트 카드 태그 뱃지 탭', () {
    cujCase(
      'happy: 태그 4개면 최대 3개 + overflow(# +1) 표시',
      app: Scaffold(
        body: MinglitEventCard(
          event: _makeEventWithTags([
            _makeTag('소개팅'),
            _makeTag('와인'),
            _makeTag('루프탑'),
            _makeTag('강남'),
          ]),
          onTap: () {},
          onTagTap: (tag) => tappedCardTags.add(tag.name),
        ),
      ),
      body: (t) async {
        expect(find.text('#소개팅'), findsOneWidget);
        expect(find.text('#와인'), findsOneWidget);
        expect(find.text('#루프탑'), findsOneWidget);
        expect(find.text('#+1'), findsOneWidget);

        await t.tap(find.text('#소개팅'));
        await t.pumpAndSettle();
        expect(tappedCardTags, ['소개팅']);
      },
    );

    cujCase(
      'edge: 태그 없음이면 뱃지 영역 미노출',
      app: Scaffold(
        body: MinglitEventCard(
          event: _makeEventWithTags(const []),
          onTap: () {},
        ),
      ),
      body: (t) async {
        expect(find.textContaining('#'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-5: 태그 페이지 이벤트 목록 렌더링 (FR-5)
  // ---------------------------------------------------------------------------

  cujGroup('1-5', '태그 페이지 이벤트 목록', () {
    cujCase(
      'happy: 이벤트 목록 렌더링',
      app: const TagEventListPage(tagId: 'tag-클럽', tagName: '클럽'),
      overrides: base,
      body: (t) async {
        expect(find.text('Test Event 1'), findsOneWidget);
        expect(find.text('Test Event 2'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 빈 상태 → 안내 메시지',
      app: const TagEventListPage(tagId: 'tag-클럽', tagName: '클럽'),
      overrides: () {
        // edge case: 빈 이벤트 목록 — default stub 덮어씀
        when(
          () => mockTagRepo.getPartiesByTag(
            any(),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => []);
        return base();
      },
      body: (t) async {
        expect(find.text('아직 이 태그의 이벤트가 없어요'), findsOneWidget);
      },
    );
  });
}
