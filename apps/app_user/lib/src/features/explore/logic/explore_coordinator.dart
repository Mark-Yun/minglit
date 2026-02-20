import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'explore_coordinator.g.dart';

@riverpod
ExploreCoordinator exploreCoordinator(Ref ref) {
  return ExploreCoordinator(ref.read(goRouterProvider));
}

class ExploreCoordinator {
  ExploreCoordinator(this._router);

  final GoRouter _router;

  void pushEventCuration(EventFeedType type) {
    unawaited(_router.push(EventCurationRoute(type: type).location));
  }

  void pushEventDetail(String eventId) {
    unawaited(_router.push(EventDetailRoute(eventId: eventId).location));
  }
}
