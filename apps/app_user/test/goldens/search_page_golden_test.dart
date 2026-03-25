@Tags(['golden'])
library;

import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  group('SearchPage golden', () {
    testWidgets('initial empty state', (tester) async {
      final mockEvent = MockEventCoordinator();

      await expectPageGolden(
        tester,
        page: const SearchPage(),
        goldenFileName: 'goldens/search_page_empty.png',
        overrides: [
          eventCoordinatorProvider.overrideWithValue(mockEvent),
          searchQueryProvider.overrideWithValue(''),
          searchResultsProvider.overrideWith((_) async => <Event>[]),
        ],
      );
    });
  });
}
