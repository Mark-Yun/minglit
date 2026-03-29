@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

/// Returns an empty string as the initial search query for golden tests.
class _EmptySearchQuery extends SearchQuery {
  @override
  String build() => '';
}

void main() {
  goldenTest(
    'SearchPage initial empty state',
    fileName: 'search_page_empty',
    pumpBeforeTest: pumpAndDumpTree('search_page_empty'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'initial empty state',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const SearchPage(),
              overrides: [
                eventCoordinatorProvider.overrideWithValue(
                  MockEventCoordinator(),
                ),
                searchQueryProvider.overrideWith(_EmptySearchQuery.new),
                searchResultsProvider.overrideWith((_) async => <Event>[]),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'SearchPage initial empty state (dark)',
    fileName: 'search_page_empty_dark',
    pumpBeforeTest: pumpAndDumpTree('search_page_empty_dark'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'initial empty state (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const SearchPage(),
              brightness: Brightness.dark,
              overrides: [
                eventCoordinatorProvider.overrideWithValue(
                  MockEventCoordinator(),
                ),
                searchQueryProvider.overrideWith(_EmptySearchQuery.new),
                searchResultsProvider.overrideWith((_) async => <Event>[]),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
