import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ticket_coordinator.g.dart';

@riverpod
TicketCoordinator ticketCoordinator(Ref ref) {
  return TicketCoordinator(ref.read(goRouterProvider));
}

class TicketCoordinator {
  TicketCoordinator(this._router);

  final GoRouter _router;

  void pushEventDetail(String eventId) {
    unawaited(_router.push(EventDetailRoute(eventId: eventId).location));
  }
}
