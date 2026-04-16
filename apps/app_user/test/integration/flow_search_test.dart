import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/golden_capture.dart';
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
      final capture = GoldenCapture('flow_u_search');
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/search',
          additionalOverrides: searchOverrides(),
        ),
      );
      await tester.pump();
      await tester.pump();

      await capture.setup(tester, 0); // 검색 화면 초기

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
      final capture = GoldenCapture('flow_u_search');
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

      await capture.after(tester, 1); // 검색 결과 표시

      expect(find.byType(MinglitEventCard), findsWidgets);
      expect(find.text('Test Event 0'), findsOneWidget);
    });

    testWidgets('검색 결과 없음 → 결과 없음 메시지 표시', (tester) async {
      setKoreanLocale(tester);
      final capture = GoldenCapture('flow_u_search');

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

      await capture.after(tester, 2); // 검색 결과 없음

      // Fix #997: empty state 개선 — 아이콘 + 범용 메시지로 변경
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
      expect(find.text('다른 키워드로 시도해보세요.'), findsOneWidget);
    });

    testWidgets('키워드 칩 탭 → 검색 쿼리 즉시 업데이트', (tester) async {
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

      // Fix #997: 검색 초기 상태에 키워드 제안 칩 표시
      expect(find.text('파티'), findsOneWidget);

      // 칩 탭 → 디바운스 없이 즉시 searchQueryProvider 업데이트
      await tester.tap(find.text('파티'));
      await tester.pump();
      await tester.pump();

      // 텍스트 필드가 칩 키워드로 업데이트됨
      expect(find.widgetWithText(TextField, '파티'), findsOneWidget);
      // 결과 로드 (queryProvider 즉시 업데이트됨)
      await tester.pump();
      expect(find.byType(MinglitEventCard), findsWidgets);
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
}
