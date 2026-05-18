// CUJ tests — discovery / tag-discovery
//
// 대응 spec: docs/features/discovery/tag-discovery/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// Fix #2561: discovery 카테고리 CUJ integration test 전무 해소 (tag-discovery)

import 'package:app_user/src/features/home/widgets/featured_tag_chip_bar.dart';
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late _MockTagRepository mockTagRepo;
  late _FakeTagCoordinator fakeCoordinator;

  setUp(() {
    mockTagRepo = _MockTagRepository();
    fakeCoordinator = _FakeTagCoordinator();
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
