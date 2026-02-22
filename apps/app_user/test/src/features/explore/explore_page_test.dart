import 'package:app_user/src/features/explore/explore_page.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoRouter extends Mock implements GoRouter {}

class _MockEventRepository extends Mock implements EventRepository {}

void main() {
  late _MockGoRouter mockRouter;
  late _MockEventRepository mockEventRepository;

  setUp(() {
    mockRouter = _MockGoRouter();
    mockEventRepository = _MockEventRepository();

    when(() => mockRouter.push(any())).thenAnswer((_) async => null);

    // Mock getEventsByType for all feed types
    // (used by recommendationEventsProvider)
    for (final type in EventFeedType.values) {
      when(
        () => mockEventRepository.getEventsByType(
          type: type,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);
    }
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        goRouterProvider.overrideWithValue(mockRouter),
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const ExplorePage(),
      ),
    );
  }

  group('ExplorePage', () {
    testWidgets('renders 탐색 app bar title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('탐색'), findsOneWidget);
    });

    testWidgets('renders tab bar with 추천 and 검색 tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('추천'), findsOneWidget);
      expect(find.text('검색'), findsOneWidget);
    });

    testWidgets('renders search bar with hint text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('이벤트 검색'), findsOneWidget);
    });

    testWidgets('renders sort chips in recommendation tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('추천순'), findsOneWidget);
      expect(find.text('마감임박'), findsOneWidget);
      expect(find.text('가까운날짜'), findsOneWidget);
    });

    testWidgets('renders toggle chips in recommendation tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('가까운 거리'), findsOneWidget);
      expect(find.text('참여 가능'), findsOneWidget);
    });

    testWidgets('does not render old filter chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('위치'), findsNothing);
      expect(find.text('가격'), findsNothing);
      expect(find.text('날짜'), findsNothing);
    });

    testWidgets('does not render curation section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('큐레이션'), findsNothing);
      expect(find.text('내 주변 파티'), findsNothing);
      expect(find.text('신규 오픈'), findsNothing);
      expect(find.text('마감 임박'), findsNothing);
      expect(find.text('얼리버드 특가'), findsNothing);
    });

    testWidgets('does not render AI 추천 section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('AI 추천'), findsNothing);
    });

    testWidgets('shows empty state when no recommendation events', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('추천 이벤트가 없습니다'), findsOneWidget);
    });

    testWidgets('shows search empty state on 검색 tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap 검색 tab
      await tester.tap(find.text('검색'));
      await tester.pumpAndSettle();

      expect(find.text('검색어를 입력하세요'), findsOneWidget);
    });

    testWidgets('chip bar is not visible in 검색 tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Switch to 검색 tab
      await tester.tap(find.text('검색'));
      await tester.pumpAndSettle();

      // Sort chips should not be visible in search tab
      expect(find.text('추천순'), findsNothing);
      expect(find.text('마감임박'), findsNothing);
    });
  });
}
