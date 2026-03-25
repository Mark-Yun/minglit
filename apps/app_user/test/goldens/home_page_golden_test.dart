@Tags(['golden'])
library;

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  group('HomePage golden', () {
    final baseTime = DateTime(2026, 5, 10, 19);

    List<dynamic> buildOverrides({
      List<Event> events = const [],
      bool hasMore = false,
    }) {
      final mockHome = MockHomeCoordinator();
      final mockEvent = MockEventCoordinator();
      final mockAuth = MockAuthCoordinator();

      return [
        homeCoordinatorProvider.overrideWithValue(mockHome),
        eventCoordinatorProvider.overrideWithValue(mockEvent),
        authCoordinatorProvider.overrideWithValue(mockAuth),
        activeFiltersProvider.overrideWith(NoFiltersNotifier.new),
        recommendationFeedProvider.overrideWith(
          () => _FakeRecommendationFeedNotifier(
            events: events,
            hasMore: hasMore,
          ),
        ),
      ];
    }

    testWidgets('empty feed', (tester) async {
      await expectPageGolden(
        tester,
        page: const HomePage(),
        goldenFileName: 'goldens/home_page_empty.png',
        overrides: buildOverrides(),
      );
    });

    testWidgets('with events', (tester) async {
      final events = List.generate(
        3,
        (i) => Event(
          id: 'e$i',
          partyId: 'p1',
          startTime: baseTime.add(Duration(days: i + 1)),
          endTime: baseTime.add(Duration(days: i + 1, hours: 2)),
          createdAt: baseTime,
          updatedAt: baseTime,
          title: '이벤트 ${i + 1}',
          currentParticipants: (i + 1) * 5,
        ),
      );

      await expectPageGolden(
        tester,
        page: const HomePage(),
        goldenFileName: 'goldens/home_page_with_events.png',
        overrides: buildOverrides(events: events),
      );
    });
  });
}

class _FakeRecommendationFeedNotifier extends RecommendationFeedNotifier {
  _FakeRecommendationFeedNotifier({
    required List<Event> events,
    required bool hasMore,
  }) : _events = events,
       _hasMore = hasMore;

  final List<Event> _events;
  final bool _hasMore;

  @override
  Future<RecommendationFeedState> build() async => RecommendationFeedState(
    events: _events,
    serverOffset: 0,
    hasMore: _hasMore,
  );
}
