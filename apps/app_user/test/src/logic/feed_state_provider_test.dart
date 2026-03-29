import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/mocks.dart';
import '../../utils/test_utils.dart';

void main() {
  final now = DateTime.now();

  setUpAll(() {
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
    Log.clear();
    for (final type in EventFeedType.values) {
      when(
        () => mockEventRepository.getEventsByType(
          type: type,
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);
    }
  });

  ProviderContainer makeContainer() {
    return createContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        activeFiltersProvider.overrideWith(_NoFiltersNotifier.new),
      ],
    );
  }

  group('FeedStateProvider error logging', () {
    test('loadMore 에러 시 Log.e 호출 확인', () async {
      // Page 0: success
      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
        ),
      ).thenAnswer((_) async => makeEvents(10));

      // Page 1: throws
      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          offset: 10,
        ),
      ).thenThrow(Exception('Test network error'));

      final container = makeContainer();
      await container.read(recommendationFeedProvider.future);

      // Trigger error path
      await container.read(recommendationFeedProvider.notifier).loadMore();

      // Verify error was logged
      final logs = Log.export();
      expect(
        logs,
        contains('[FeedStateProvider] Load more Error'),
        reason: 'Log.e should be called with error message on loadMore failure',
      );
    });

    test('loadMore 에러 시 기존 이벤트 보존 + isLoadingMore=false', () async {
      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
        ),
      ).thenAnswer((_) async => makeEvents(10));

      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          offset: 10,
        ),
      ).thenThrow(Exception('Network error'));

      final container = makeContainer();
      await container.read(recommendationFeedProvider.future);
      await container.read(recommendationFeedProvider.notifier).loadMore();

      final state = await container.read(recommendationFeedProvider.future);
      expect(state.events, hasLength(10));
      expect(state.isLoadingMore, isFalse);
    });
  });
}

class _NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}
