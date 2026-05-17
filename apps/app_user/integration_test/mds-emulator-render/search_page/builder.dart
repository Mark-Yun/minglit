// SearchPageBuilder — search_page 전용 fluent API.

import 'package:app_user/src/features/search/logic/search_coordinator.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';
import '../_mocks/data.dart';
import '../_mocks/notifiers.dart';

class SearchPageBuilder extends MdsScreenBuilder<SearchPage> {
  SearchPageBuilder()
    : super(
        page: const SearchPage(),
        base: [
          searchCoordinatorProvider.overrideWithValue(MockSearchCoordinator()),
          // 기본: 빈 쿼리 (키워드 제안 노출).
          searchQueryProvider.overrideWith(
            () => LockedSearchQueryNotifier(''),
          ),
          searchResultsProvider.overrideWith((_) async => <Event>[]),
        ],
      );

  /// 검색 결과 [count]건 표시 (쿼리 "test" 고정).
  SearchPageBuilder withResults([int count = 3]) {
    addOverride(
      searchQueryProvider.overrideWith(
        () => LockedSearchQueryNotifier('test'),
      ),
    );
    addOverride(
      searchResultsProvider.overrideWith(
        (_) async => mockEvents(count: count),
      ),
    );
    return this;
  }

  /// 검색 결과 0건 (쿼리 "없는검색어" 고정).
  SearchPageBuilder withNoResults() {
    addOverride(
      searchQueryProvider.overrideWith(
        () => LockedSearchQueryNotifier('없는검색어'),
      ),
    );
    addOverride(
      searchResultsProvider.overrideWith((_) async => <Event>[]),
    );
    return this;
  }

  /// 다크 모드 토글.
  SearchPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
