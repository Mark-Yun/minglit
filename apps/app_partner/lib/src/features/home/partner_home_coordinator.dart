import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final partnerHomeCoordinatorProvider = Provider<PartnerHomeCoordinator>((ref) {
  return PartnerHomeCoordinator(ref.read(goRouterProvider));
});

class PartnerHomeCoordinator {
  PartnerHomeCoordinator(this._router);

  final GoRouter _router;

  void pushNotificationCenter() {
    unawaited(_router.push(const NotificationCenterRoute().location));
  }

  void pushApplicationList() {
    unawaited(_router.push(const ApplicationListRoute().location));
  }
}
