import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../goldens/golden_test_helpers.dart'
    show MockHomeCoordinator, NoFiltersNotifier;
import 'screenshot_scenario.dart';

class HomeScenarios {
  static final DateTime _baseTime = DateTime(2026, 5, 10, 19);

  static List<Event> _threeEvents() => List.generate(
    3,
    (i) => Event(
      id: 'e$i',
      partyId: 'p1',
      startTime: _baseTime.add(Duration(days: i + 1)),
      endTime: _baseTime.add(Duration(days: i + 1, hours: 2)),
      createdAt: _baseTime,
      updatedAt: _baseTime,
      title: '이벤트 ${i + 1}',
      currentParticipants: (i + 1) * 5,
    ),
  );

  static List<dynamic> _buildOverrides({
    List<Event> events = const [],
    bool hasMore = false,
  }) => [
    homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator()),
    activeFiltersProvider.overrideWith(NoFiltersNotifier.new),
    recommendationFeedProvider.overrideWith(
      () => FakeRecommendationFeedNotifier(events: events, hasMore: hasMore),
    ),
  ];

  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'home_page_empty',
      page: const HomePage(),
      overrides: _buildOverrides(),
    ),
    ScreenshotScenario(
      name: 'home_page_with_events',
      page: const HomePage(),
      overrides: _buildOverrides(events: _threeEvents()),
    ),
    ScreenshotScenario(
      name: 'home_page_empty_dark',
      page: const HomePage(),
      brightness: Brightness.dark,
      overrides: _buildOverrides(),
    ),
    ScreenshotScenario(
      name: 'home_page_with_events_dark',
      page: const HomePage(),
      brightness: Brightness.dark,
      overrides: _buildOverrides(events: _threeEvents()),
    ),
  ];
}

class FakeRecommendationFeedNotifier extends RecommendationFeedNotifier {
  FakeRecommendationFeedNotifier({
    required this.events,
    required this.hasMore,
  });

  final List<Event> events;
  final bool hasMore;

  @override
  Future<RecommendationFeedState> build() async => RecommendationFeedState(
    events: events,
    serverOffset: 0,
    hasMore: hasMore,
  );
}
