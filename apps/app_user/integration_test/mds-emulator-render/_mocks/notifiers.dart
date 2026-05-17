// 화면 builder 들이 공통으로 쓰는 Notifier override.

import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// 필터 (location, eligibility) 비활성화.
class NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}

/// 빈 추천 피드.
class EmptyRecommendationFeedNotifier extends RecommendationFeedNotifier {
  @override
  Future<RecommendationFeedState> build() async =>
      const RecommendationFeedState(
        events: [],
        serverOffset: 0,
        hasMore: false,
      );
}

/// 지정한 event 목록을 가진 추천 피드.
class StaticRecommendationFeedNotifier extends RecommendationFeedNotifier {
  StaticRecommendationFeedNotifier(this._events);

  final List<Event> _events;

  @override
  Future<RecommendationFeedState> build() async => RecommendationFeedState(
        events: _events,
        serverOffset: _events.length,
        hasMore: false,
      );
}
