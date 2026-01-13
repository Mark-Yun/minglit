import 'dart:async';

import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_coordinator.g.dart';

@riverpod
EventCoordinator eventCoordinator(Ref ref) {
  return EventCoordinator();
}

class EventCoordinator {
  void goToEventDetail(BuildContext context, String eventId) {
    unawaited(EventDetailRoute(eventId: eventId).push<void>(context));
  }
}
