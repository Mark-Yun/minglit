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

    // Mock getPersonalizedRecommendations for aiRecommendationsProvider
    when(
      () => mockEventRepository.getPersonalizedRecommendations(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);

    // Mock getEventsByType for all feed types
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

    testWidgets('renders 4 filter chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('참여 가능'), findsOneWidget);
      expect(find.text('위치'), findsOneWidget);
      expect(find.text('가격'), findsOneWidget);
      expect(find.text('날짜'), findsOneWidget);
    });

    testWidgets('renders curation section with 4 categories', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('큐레이션'), findsOneWidget);
      expect(find.text('내 주변 파티'), findsOneWidget);
      expect(find.text('신규 오픈'), findsOneWidget);
      expect(find.text('마감 임박'), findsOneWidget);
      expect(find.text('얼리버드 특가'), findsOneWidget);
    });

    testWidgets('renders sort labels as subtitles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('거리순'), findsOneWidget);
      expect(find.text('최신순'), findsOneWidget);
      expect(find.text('마감순'), findsOneWidget);
      expect(find.text('가격순'), findsOneWidget);
    });

    testWidgets('renders category icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.fiber_new), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.local_offer), findsOneWidget);
    });

    testWidgets('renders chevron icons for navigation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
    });

    testWidgets('renders 4 Card widgets in curation grid', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Card), findsNWidgets(4));
    });

    testWidgets('shows search empty state on 검색 tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap 검색 tab
      await tester.tap(find.text('검색'));
      await tester.pumpAndSettle();

      expect(find.text('검색어를 입력하세요'), findsOneWidget);
    });
  });
}
