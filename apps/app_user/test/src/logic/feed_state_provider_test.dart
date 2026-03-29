import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/mocks.dart';

void main() {
  late MockEventRepository mockEventRepository;

  setUp(() {
    Log.clear();
    mockEventRepository = MockEventRepository();
  });

  /// Builds a ProviderContainer with overrides for feed state tests.
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        activeFiltersProvider.overrideWith(_NoFiltersNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Stubs [getEventsByType] for all feed types with [answer].
  void stubGetEventsByType(
    Future<List<Event>> Function(Invocation) answer,
  ) {
    for (final type in EventFeedType.values) {
      when(
        () => mockEventRepository.getEventsByType(
          type: type,
          offset: any(named: 'offset'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
          blockedPartnerIds: any(
            named: 'blockedPartnerIds',
          ),
        ),
      ).thenAnswer(answer);
    }
  }

  group('RecommendationFeedNotifier', () {
    group('loadMore', () {
      // Fix #691: 에러 발생 시 Log.e 호출 + graceful 처리 검증
      test('logs error via Log.e and restores state on exception', () async {
        var callCount = 0;

        stubGetEventsByType((_) async {
          callCount++;
          if (callCount == 1) {
            return List.generate(
              10,
              (i) => _createMinimalEvent(id: 'event_$i'),
            );
          }
          throw Exception('Test: network timeout');
        });

        final container = createContainer();
        final notifier = container.read(recommendationFeedProvider.notifier);

        // Wait for initial build to complete
        await container.read(recommendationFeedProvider.future);

        // Verify initial state loaded successfully
        final stateBefore = container.read(recommendationFeedProvider).value!;
        expect(stateBefore.events, isNotEmpty);
        expect(stateBefore.hasMore, isTrue);

        // Trigger loadMore — should catch the exception
        await notifier.loadMore();

        // Verify Log.e was called with the expected error context
        final logOutput = Log.export();
        expect(logOutput, contains('[FeedStateProvider]'));
        expect(logOutput, contains('Load more Error'));

        // Verify state was restored (not in error state, events preserved)
        final stateAfter = container.read(recommendationFeedProvider).value;
        expect(stateAfter, isNotNull);
        expect(stateAfter!.events.length, equals(stateBefore.events.length));
        expect(stateAfter.isLoadingMore, isFalse);
      });

      test('preserves existing events when loadMore fails', () async {
        var callCount = 0;

        stubGetEventsByType((_) async {
          callCount++;
          if (callCount == 1) {
            return List.generate(
              10,
              (i) => _createMinimalEvent(id: 'event_$i'),
            );
          }
          throw Exception('Server error');
        });

        final container = createContainer();
        final notifier = container.read(recommendationFeedProvider.notifier);
        await container.read(recommendationFeedProvider.future);

        final eventsBefore = container
            .read(recommendationFeedProvider)
            .value!
            .events;

        await notifier.loadMore();

        final eventsAfter = container
            .read(recommendationFeedProvider)
            .value!
            .events;
        expect(eventsAfter.length, equals(eventsBefore.length));
      });
    });
  });
}

/// Notifier that starts with all filters disabled to avoid triggering
/// location services or eligibility checks.
class _NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}

/// Creates a minimal [Event] for testing.
Event _createMinimalEvent({required String id}) {
  final now = DateTime.now();
  return Event(
    id: id,
    partyId: 'party_1',
    title: 'Test Event $id',
    startTime: now.add(const Duration(hours: 1)),
    endTime: now.add(const Duration(hours: 3)),
    maxParticipants: 10,
    status: 'published',
    createdAt: now,
    updatedAt: now,
  );
}
