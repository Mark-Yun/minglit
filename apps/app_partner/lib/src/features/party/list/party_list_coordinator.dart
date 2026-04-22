import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final partyListCoordinatorProvider = Provider<PartyListCoordinator>((ref) {
  return PartyListCoordinator(ref.read(goRouterProvider));
});

class PartyListCoordinator {
  const PartyListCoordinator(this._router);

  final GoRouter _router;

  // Fix #1680: context.push() fails silently when called from a page pushed via
  // _router.push() — unawaited() drops async errors so the catch block is never
  // reached. Use GoRouter instance directly, matching MoreCoordinator pattern.
  void goToCreate() {
    unawaited(_router.push(const PartyCreateRoute().location));
  }

  void goToDetail(String partyId) {
    unawaited(_router.push(PartyDetailRoute(partyId: partyId).location));
  }
}
