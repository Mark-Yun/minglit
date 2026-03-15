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
        ),
      ).thenAnswer((_) async => []);
    }
  });

  Widget createTestWidget({List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        // Disable active filters to avoid triggering location services
        activeFiltersProvider.overrideWith(
          _NoFiltersNotifier.new,
        ),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const HomePage(),
      ),
    );
  }

  group('HomePage', () {
    testWidgets('renders notification bell icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
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
        ),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Test Party Event'), findsOneWidget);
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
