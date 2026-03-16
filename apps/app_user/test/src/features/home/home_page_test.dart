import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:app_user/src/features/home/home_page.dart';
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

  setUp(() {
    mockEventRepository = MockEventRepository();

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
  }) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        // Disable active filters to avoid triggering location services
        activeFiltersProvider.overrideWith(
          _NoFiltersNotifier.new,
        ),
        // Default: unauthenticated. Pass currentUser to test logged-in state.
        currentUserProvider.overrideWith((_) => currentUser),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const HomePage(),
      ),
    );
  }

  group('HomePage', () {
    testWidgets('renders notification bell icon when logged in', (
      tester,
    ) async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user1');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.userMetadata).thenReturn({'full_name': 'Test User'});

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

      // SliverFillRemaining(loading) shows when events are empty and hasMore=true.
      // SliverToBoxAdapter(isLoadingMore) follows in the sliver list but is not
      // built because SliverFillRemaining fills the remaining viewport first.
      expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show loading indicator when hasMore is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            recommendationFeedProvider.overrideWith(
              _MockNoMoreNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(MinglitCircularProgressIndicator), findsNothing);
    });
  });
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
