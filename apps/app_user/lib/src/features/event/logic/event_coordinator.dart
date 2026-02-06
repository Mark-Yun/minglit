import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_coordinator.g.dart';

@riverpod
EventCoordinator eventCoordinator(Ref ref) {
  return EventCoordinator(ref.read(goRouterProvider));
}

class EventCoordinator {
  EventCoordinator(this._router);

  final GoRouter _router;

  void pushEventDetail(String eventId) {
    unawaited(_router.push(EventDetailRoute(eventId: eventId).location));
  }

  void goToEventDetail(String eventId) {
    _router.go(EventDetailRoute(eventId: eventId).location);
  }

  void pushEventCuration(EventFeedType type) {
    unawaited(_router.push(EventCurationRoute(type: type).location));
  }

  void goToApplicationWizard(
    String eventId, {
    String? ticketId,
  }) {
    unawaited(
      _router.push(
        EventApplicationRoute(eventId: eventId, ticketId: ticketId).location,
      ),
    );
  }
}
