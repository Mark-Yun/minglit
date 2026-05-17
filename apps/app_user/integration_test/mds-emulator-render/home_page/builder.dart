// HomePageBuilder — home_page 전용 fluent API.
//
// 추가될 메서드 (예시):
//   .withTags(int n)
//   .withNowBar(...)
//
// 기본 상태: 빈 추천 피드 (loaded 0 events).

import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';
import '../_mocks/data.dart';
import '../_mocks/notifiers.dart';

class HomePageBuilder extends MdsScreenBuilder<HomePage> {
  HomePageBuilder()
      : super(
          page: const HomePage(),
          base: [
            // 모든 state 에 공통인 것만. provider 충돌 방지 위해 state 별로
            // 달라질 수 있는 것 (feed 등) 은 fluent 메서드가 명시적으로 추가.
            homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator()),
            activeFiltersProvider.overrideWith(NoFiltersNotifier.new),
          ],
        );

  /// 빈 추천 피드.
  HomePageBuilder empty() {
    addOverride(
      recommendationFeedProvider
          .overrideWith(EmptyRecommendationFeedNotifier.new),
    );
    return this;
  }

  /// 추천 피드를 [count] 개 mock event 로 채운다.
  HomePageBuilder withEvents([int count = 3]) {
    addOverride(
      recommendationFeedProvider.overrideWith(
        () => StaticRecommendationFeedNotifier(mockEvents(count: count)),
      ),
    );
    return this;
  }

  /// 다크 모드 토글.
  HomePageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
