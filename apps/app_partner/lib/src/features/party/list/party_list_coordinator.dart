import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Fix #1680: inject GoRouter from provider so push() uses the root router
// instance, not the shell-branch's nested navigator. context.push() from
// within a StatefulShellBranch can fail silently when crossing branch
// boundaries (e.g., HomeBranch → MoreBranch).
final partyListCoordinatorProvider = Provider<PartyListCoordinator>((ref) {
  return PartyListCoordinator(ref.read(goRouterProvider));
});

class PartyListCoordinator {
  const PartyListCoordinator(this._router);

  final GoRouter _router;

  void goToCreate() {
    unawaited(_router.push(const PartyCreateRoute().location));
  }

  void goToDetail(String partyId) {
    unawaited(_router.push(PartyDetailRoute(partyId: partyId).location));
  }

  void goToEventDetail(String partyId, String eventId) {
    unawaited(
      _router.push(EventDetailRoute(partyId: partyId, eventId: eventId).location),
    );
  }
}
