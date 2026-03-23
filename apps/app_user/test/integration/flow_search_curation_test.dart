import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:app_user/src/features/party/party_curation_page.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  // ────────────────────────────────────────────────────────────────────────
  // SearchPage
  // ────────────────────────────────────────────────────────────────────────
  group('SearchPage', () {
    /// Override that returns results based on current searchQueryProvider.
    List<dynamic> searchOverrides({List<Event>? results}) {
      return [
        searchResultsProvider.overrideWith((ref) async {
          final query = ref.watch(searchQueryProvider);
          if (query.isEmpty) return <Event>[];
          return results ?? <Event>[];
        }),
      ];
    }

    testWidgets('/search 라우트 → SearchPage 이동', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/search',
          additionalOverrides: searchOverrides(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('빈 쿼리 → 검색 아이콘 + "검색어를 입력하세요"', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/search',
          additionalOverrides: searchOverrides(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('검색어를 입력하세요'), findsOneWidget);
    });

    testWidgets('텍스트 입력 → 500ms 디바운스 → 결과 로딩', (tester) async {
      setKoreanLocale(tester);
      final mockEvents = createMockEventsForTest();

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/search',
          additionalOverrides: searchOverrides(results: mockEvents),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Type into search field
      await tester.enterText(find.byType(TextField), '테스트');

      // Before debounce — still shows placeholder
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('검색어를 입력하세요'), findsOneWidget);

      // After debounce (500ms) — results should appear
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(); // rebuild

      expect(find.byType(MinglitEventCard), findsWidgets);
    });

    testWidgets('검색 결과 있음 → 이벤트 카드 리스트', (tester) async {
      setKoreanLocale(tester);
      final mockEvents = createMockEventsForTest(count: 3);

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/search',
          additionalOverrides: searchOverrides(results: mockEvents),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextField), '파티');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.byType(MinglitEventCard), findsWidgets);
      expect(find.text('Test Event 0'), findsOneWidget);
    });

    testWidgets('검색 결과 없음 → "쿼리" 검색 결과가 없습니다', (tester) async {
      setKoreanLocale(tester);

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/search',
          additionalOverrides: searchOverrides(),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextField), '없는쿼리');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('"없는쿼리" 검색 결과가 없습니다'), findsOneWidget);
    });

    testWidgets('결과 카드 tap → EventDetailPage 이동', (tester) async {
      setKoreanLocale(tester);
      final mockEvents = createMockEventsForTest(count: 1);

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/search',
          additionalOverrides: searchOverrides(results: mockEvents),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextField), '테스트');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      await tester.tap(find.byType(MinglitEventCard).first);
      await tester.pump();
      await tester.pump();

      expect(find.byType(EventDetailPage), findsOneWidget);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // PartyCurationPage
  // ────────────────────────────────────────────────────────────────────────
  group('PartyCurationPage', () {
    testWidgets('큐레이션 페이지 렌더링 (newArrivals 타입)', (tester) async {
      setKoreanLocale(tester);
      final mockEvents = createMockEventsForTest(count: 3);

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/curation',
          feedEvents: mockEvents,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartyCurationPage), findsOneWidget);
      expect(find.text(EventFeedType.newArrivals.title), findsOneWidget);
      expect(find.byType(MinglitEventCard), findsWidgets);
    });

    testWidgets('큐레이션 페이지 렌더링 (closingSoon 타입)', (tester) async {
      setKoreanLocale(tester);
      final mockEvents = createMockEventsForTest(count: 3);

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/curation?type=closing-soon',
          feedEvents: mockEvents,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartyCurationPage), findsOneWidget);
      expect(find.text(EventFeedType.closingSoon.title), findsOneWidget);
    });

    testWidgets('큐레이션 페이지 렌더링 (nearest 타입)', (tester) async {
      setKoreanLocale(tester);
      final mockEvents = createMockEventsForTest(count: 3);

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/curation?type=nearest',
          feedEvents: mockEvents,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartyCurationPage), findsOneWidget);
      expect(find.text(EventFeedType.nearest.title), findsOneWidget);
    });

    testWidgets('큐레이션 페이지 렌더링 (earlyBird 타입)', (tester) async {
      setKoreanLocale(tester);
      final mockEvents = createMockEventsForTest(count: 3);

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/curation?type=early-bird',
          feedEvents: mockEvents,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartyCurationPage), findsOneWidget);
      expect(find.text(EventFeedType.earlyBird.title), findsOneWidget);
    });

    testWidgets('빈 큐레이션 → "현재 표시할 파티가 없습니다."', (tester) async {
      setKoreanLocale(tester);

      await tester.pumpWidget(
        createTestApp(initialLocation: '/curation'),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('현재 표시할 파티가 없습니다.'), findsOneWidget);
    });
  });
}
