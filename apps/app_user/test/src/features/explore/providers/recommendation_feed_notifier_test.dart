import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  final now = DateTime.now();

  setUpAll(() {
    // Required by mocktail when any(named: 'type') is used in verify()
    registerFallbackValue(EventFeedType.newArrivals);
  });

  Event makeEvent({required String id}) {
    return Event(
      id: id,
      partyId: 'party1',
      startTime: now.add(const Duration(days: 1)),
      endTime: now.add(const Duration(days: 1, hours: 2)),
      createdAt: now,
      updatedAt: now,
      tickets: [
        Ticket(
          id: 't$id',
          name: 'General',
          price: 10000,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }

  List<Event> makeEvents(int count, {int startIndex = 0}) {
    return List.generate(
      count,
      (i) => makeEvent(id: 'e${startIndex + i}'),
    );
  }

  late MockEventRepository mockEventRepository;

  setUp(() {
    mockEventRepository = MockEventRepository();
    // Default: return empty for all feed types + any offset.
    // Only specify 'type' and 'offset' — extra args in the actual invocation
    // are ignored by mocktail's lenient matching.
    for (final type in EventFeedType.values) {
      when(
        () => mockEventRepository.getEventsByType(
          type: type,
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);
    }
  });

  /// Stubs a specific page for EventFeedType.newArrivals.
  void stubPage({
    required int offset,
    required List<Event> returns,
  }) {
    when(
      () => mockEventRepository.getEventsByType(
        type: EventFeedType.newArrivals,
        offset: offset,
      ),
    ).thenAnswer((_) async => returns);
  }

  ProviderContainer makeContainer() {
    return createContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        // Disable filters so filteredEventsProvider passes events through
        activeFiltersProvider.overrideWith(_NoFiltersNotifier.new),
      ],
    );
  }

  group('RecommendationFeedNotifier', () {
    group('build() — 초기 로드', () {
      test('offset=0으로 첫 페이지 10개 로드', () async {
        stubPage(offset: 0, returns: makeEvents(10));

        final container = makeContainer();
        final state = await container.read(recommendationFeedProvider.future);

        expect(state.events, hasLength(10));
        expect(state.serverOffset, equals(10));
        expect(state.hasMore, isTrue);
        expect(state.isLoadingMore, isFalse);
      });

      test('0개 반환 시 hasMore=false', () async {
        // Default setup returns [] → hasMore=false
        final container = makeContainer();
        final state = await container.read(recommendationFeedProvider.future);

        expect(state.events, isEmpty);
        expect(state.serverOffset, equals(0));
        expect(state.hasMore, isFalse);
      });
    });

    group('loadMore() — 다음 페이지 추가', () {
      test('두번째 페이지 append — 총 20개', () async {
        stubPage(offset: 0, returns: makeEvents(10));
        stubPage(offset: 10, returns: makeEvents(10, startIndex: 10));

        final container = makeContainer();
        await container.read(recommendationFeedProvider.future);

        await container.read(recommendationFeedProvider.notifier).loadMore();

        final state = await container.read(recommendationFeedProvider.future);

        expect(state.events, hasLength(20));
        expect(state.serverOffset, equals(20));
        expect(state.hasMore, isTrue);
        expect(state.isLoadingMore, isFalse);
      });
    });

    group('마지막 페이지 — hasMore=false', () {
      test('10개 미만 반환 시 hasMore=false', () async {
        stubPage(offset: 0, returns: makeEvents(10));
        stubPage(offset: 10, returns: makeEvents(7, startIndex: 10));

        final container = makeContainer();
        await container.read(recommendationFeedProvider.future);
        await container.read(recommendationFeedProvider.notifier).loadMore();

        final state = await container.read(recommendationFeedProvider.future);

        expect(state.events, hasLength(17));
        expect(state.hasMore, isFalse);
        expect(state.isLoadingMore, isFalse);
      });

      test('hasMore=false 시 loadMore()는 no-op', () async {
        // Default setup returns [] → hasMore=false from initial load

        final container = makeContainer();
        await container.read(recommendationFeedProvider.future);

        // loadMore should be no-op (hasMore=false)
        await container.read(recommendationFeedProvider.notifier).loadMore();

        // Repository should only have been called once (initial load)
        verify(
          () => mockEventRepository.getEventsByType(
            type: any(named: 'type'),
            offset: any(named: 'offset'),
          ),
        ).called(1);
      });
    });

    group('concurrent loadMore 방지', () {
      test('동시 loadMore 호출 시 repository 1회만 호출', () async {
        var page2CallCount = 0;

        stubPage(offset: 0, returns: makeEvents(10));
        // Page 2 stub counts calls
        when(
          () => mockEventRepository.getEventsByType(
            type: EventFeedType.newArrivals,
            offset: 10,
          ),
        ).thenAnswer((_) async {
          page2CallCount++;
          return makeEvents(10, startIndex: 10);
        });

        final container = makeContainer();
        await container.read(recommendationFeedProvider.future);

        // Dispatch two concurrent loadMore() calls without awaiting
        final f1 = container
            .read(recommendationFeedProvider.notifier)
            .loadMore();
        final f2 = container
            .read(recommendationFeedProvider.notifier)
            .loadMore();
        await f1;
        await f2;

        // Second call should have been rejected by isLoadingMore guard
        expect(page2CallCount, equals(1));
      });
    });

    group('필터 변경 시 리셋', () {
      test('필터 변경 시 serverOffset 0으로 리셋 후 재로드', () async {
        // Stub for newArrivals (recommended sort)
        when(
          () => mockEventRepository.getEventsByType(
            type: EventFeedType.newArrivals,
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => makeEvents(10));

        // Stub for closingSoon filter
        when(
          () => mockEventRepository.getEventsByType(
            type: EventFeedType.closingSoon,
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => makeEvents(10));

        // Use default container (with active filters mutable)
        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
          ],
        );

        // Load first page
        final state1 = await container.read(recommendationFeedProvider.future);
        expect(state1.serverOffset, equals(10));

        // Change filter → triggers rebuild → resets pagination
        container
            .read(activeFiltersProvider.notifier)
            .setSortType(ExploreSortType.closingSoon);

        // Allow rebuild to complete
        final state2 = await container.read(recommendationFeedProvider.future);

        // Fresh page 1 after reset
        expect(state2.serverOffset, equals(10));
        expect(state2.hasMore, isTrue);
      });
    });

    group('에러 처리', () {
      test('loadMore 에러 시 기존 리스트 보존', () async {
        stubPage(offset: 0, returns: makeEvents(10));

        // Page 2 throws error
        when(
          () => mockEventRepository.getEventsByType(
            type: EventFeedType.newArrivals,
            offset: 10,
          ),
        ).thenThrow(Exception('Network error'));

        final container = makeContainer();
        await container.read(recommendationFeedProvider.future);

        // loadMore fails
        await container.read(recommendationFeedProvider.notifier).loadMore();

        final state = await container.read(recommendationFeedProvider.future);

        // Existing 10 events preserved after error
        expect(state.events, hasLength(10));
        expect(state.isLoadingMore, isFalse);
      });
    });
  });
}

/// A notifier that returns ExploreFilters with NO active filters.
/// This causes filteredEventsProvider to pass events through unchanged.
class _NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}
