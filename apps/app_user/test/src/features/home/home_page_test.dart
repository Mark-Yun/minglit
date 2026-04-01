import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late MockEventRepository mockEventRepository;
  late MockUser mockUser;

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user1');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.userMetadata).thenReturn({'full_name': 'Test User'});

    // Return empty lists for all feed types by default
    for (final type in EventFeedType.values) {
      when(
        () => mockEventRepository.getEventsByType(
          type: type,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);
    }
  });

  Widget createTestWidget({
    User? currentUser,
    List<dynamic> overrides = const [],
    MediaQueryData? mediaQueryData,
  }) {
    final page = mediaQueryData == null
        ? const HomePage()
        : MediaQuery(data: mediaQueryData, child: const HomePage());

    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        // Disable active filters to avoid triggering location services
        activeFiltersProvider.overrideWith(_NoFiltersNotifier.new),
        // Default: unauthenticated. Pass currentUser to test logged-in state.
        currentUserProvider.overrideWith((_) => currentUser),
        ...overrides.cast(),
      ],
      child: MaterialApp(theme: MinglitTheme.materialTheme, home: page),
    );
  }

  group('HomePage', () {
    testWidgets('renders notification bell icon when logged in', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(currentUser: mockUser));
      await tester.pump();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('renders search icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders filter chip bar with sort chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // ExploreFilterChipBar renders these sort chips
      expect(find.text('추천순'), findsOneWidget);
      expect(find.text('마감임박'), findsOneWidget);
      expect(find.text('가까운날짜'), findsOneWidget);
    });

    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // Multiple pumps to resolve async providers
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('추천 이벤트가 없습니다'), findsOneWidget);
    });

    testWidgets('renders event cards when data is available', (tester) async {
      final testEvents = [
        Event(
          id: 'event1',
          partyId: 'party1',
          startTime: DateTime.now().add(const Duration(days: 3)),
          endTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          title: 'Test Party Event',
          tickets: [
            Ticket(
              id: 't1',
              name: 'General',
              price: 15000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Test Party Event'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoadingMore is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            recommendationFeedProvider.overrideWith(
              _MockLoadingMoreNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      // Fix #113: SliverFillRemaining fills viewport, SliverToBoxAdapter skips
      expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);
    });

    testWidgets('wraps content in RefreshIndicator for pull-to-refresh', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows error message with retry button on feed load failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            recommendationFeedProvider.overrideWith(_MockErrorNotifier.new),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('피드를 불러오지 못했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('does not show loading indicator when hasMore is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            recommendationFeedProvider.overrideWith(_MockNoMoreNotifier.new),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(MinglitCircularProgressIndicator), findsNothing);
    });

    testWidgets('pins EventNowBar while the feed scrolls', (tester) async {
      final activeEvent = _makeActiveEvent();
      final feedEvents = List.generate(12, _makeFeedEvent);

      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => feedEvents);

      await tester.pumpWidget(
        createTestWidget(
          currentUser: mockUser,
          overrides: [
            todayActiveEventsProvider.overrideWith((_) => [activeEvent]),
            eventNowBarStateProvider(activeEvent).overrideWith(
              () => _FixedNowBarStateNotifier(EventNowBarState.matching),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final barFinder = find.byType(EventNowBar);
      final before = tester.getTopLeft(barFinder).dy;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final after = tester.getTopLeft(barFinder).dy;
      expect(before, after);
      expect(find.text('오늘 이벤트'), findsOneWidget);
    });

    testWidgets('positions EventNowBar above the bottom safe area', (
      tester,
    ) async {
      final activeEvent = _makeActiveEvent();

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          currentUser: mockUser,
          mediaQueryData: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
          ),
          overrides: [
            todayActiveEventsProvider.overrideWith((_) => [activeEvent]),
            eventNowBarStateProvider(activeEvent).overrideWith(
              () => _FixedNowBarStateNotifier(EventNowBarState.waiting),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final barContentFinder = find.ancestor(
        of: find.text('오늘 이벤트'),
        matching: find.byType(GestureDetector),
      );
      // Expected: 844 screen height - 34 safe area - 56 bar height = 754.
      const expectedTop = 844 - 34 - EventNowBar.height;
      // Expected: 844 screen height - 34 bottom safe area = 810.
      const expectedBottom = 844 - 34;
      final barTop = tester.getTopLeft(barContentFinder).dy;
      final barBottom = tester.getBottomLeft(barContentFinder).dy;
      expect(barTop, closeTo(expectedTop.toDouble(), 0.1));
      expect(barBottom, closeTo(expectedBottom.toDouble(), 0.1));
    });

    testWidgets('omits EventNowBar when there are no active events', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          currentUser: mockUser,
          mediaQueryData: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
          ),
          overrides: [
            todayActiveEventsProvider.overrideWith(
              (_) => const <TodayActiveEvent>[],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EventNowBar), findsNothing);
      expect(find.text('추천 이벤트가 없습니다'), findsOneWidget);
    });

    testWidgets('keeps the last event card above the fixed EventNowBar', (
      tester,
    ) async {
      final activeEvent = _makeActiveEvent();
      final feedEvents = List.generate(16, _makeFeedEvent);
      final lastTitle = feedEvents.last.title!;

      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => feedEvents);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          currentUser: mockUser,
          mediaQueryData: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
          ),
          overrides: [
            todayActiveEventsProvider.overrideWith((_) => [activeEvent]),
            eventNowBarStateProvider(activeEvent).overrideWith(
              () => _FixedNowBarStateNotifier(EventNowBarState.matching),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(lastTitle),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final lastCardBottom = tester.getBottomLeft(find.text(lastTitle)).dy;
      final nowBarTop = tester.getTopLeft(find.byType(EventNowBar)).dy;
      expect(lastCardBottom, lessThanOrEqualTo(nowBarTop));
    });
  });
}

TodayActiveEvent _makeActiveEvent() {
  final now = DateTime.now();
  return TodayActiveEvent(
    event: Event(
      id: 'active_event',
      partyId: 'party_active',
      title: '오늘 이벤트',
      startTime: now.add(const Duration(minutes: 40)),
      endTime: now.add(const Duration(hours: 3)),
      createdAt: now,
      updatedAt: now,
    ),
    participantStatus: 'ticket_issued',
  );
}

Event _makeFeedEvent(int index) {
  final now = DateTime.now();
  return Event(
    id: 'event_$index',
    partyId: 'party_$index',
    startTime: now.add(Duration(days: index + 1)),
    endTime: now.add(Duration(days: index + 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    title: '추천 이벤트 $index',
    tickets: [
      Ticket(
        id: 'ticket_$index',
        name: 'General',
        price: 15000,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

/// A notifier that starts with no active filters (all disabled),
/// so filteredEventsProvider passes through without triggering
/// location services or eligibility checks.
class _NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}

/// A notifier that returns isLoadingMore=true to test the loading indicator.
class _MockLoadingMoreNotifier extends RecommendationFeedNotifier {
  @override
  Future<RecommendationFeedState> build() async {
    return const RecommendationFeedState(
      events: [],
      serverOffset: 0,
      hasMore: true,
      isLoadingMore: true,
    );
  }
}

/// A notifier that throws an error to test the error state UI.
class _MockErrorNotifier extends RecommendationFeedNotifier {
  @override
  Future<RecommendationFeedState> build() async {
    throw Exception('Feed load failed');
  }
}

/// A notifier that returns hasMore=false and isLoadingMore=false.
class _MockNoMoreNotifier extends RecommendationFeedNotifier {
  @override
  Future<RecommendationFeedState> build() async {
    return const RecommendationFeedState(
      events: [],
      serverOffset: 0,
      hasMore: false,
    );
  }
}

class _FixedNowBarStateNotifier extends EventNowBarStateNotifier {
  _FixedNowBarStateNotifier(this.stateValue);

  final EventNowBarState stateValue;

  @override
  Future<EventNowBarState> build(TodayActiveEvent activeEvent) async {
    return stateValue;
  }
}
