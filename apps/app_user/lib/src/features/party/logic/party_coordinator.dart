import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final partyCoordinatorProvider = Provider<PartyCoordinator>((ref) {
  return PartyCoordinator(ref.read(goRouterProvider));
});

// Fix #634: party feature 전용 coordinator — event_coordinator 직접 참조 제거
class PartyCoordinator {
  PartyCoordinator(this._router);

  final GoRouter _router;

  void pushEventDetail(String eventId) {
    unawaited(_router.push(EventDetailRoute(eventId: eventId).location));
  }
}
