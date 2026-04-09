import 'package:app_user/src/features/search/logic/search_coordinator.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../goldens/golden_test_helpers.dart' show MockSearchCoordinator;
import 'screenshot_scenario.dart';

class EmptySearchQuery extends SearchQuery {
  @override
  String build() => '';
}

class SearchScenarios {
  static List<dynamic> _buildOverrides() => [
    searchCoordinatorProvider.overrideWithValue(MockSearchCoordinator()),
    searchQueryProvider.overrideWith(EmptySearchQuery.new),
    searchResultsProvider.overrideWith((_) async => <Event>[]),
  ];

  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'search_page_empty',
      page: const SearchPage(),
      overrides: _buildOverrides(),
    ),
    ScreenshotScenario(
      name: 'search_page_empty_dark',
      page: const SearchPage(),
      brightness: Brightness.dark,
      overrides: _buildOverrides(),
    ),
  ];
}
