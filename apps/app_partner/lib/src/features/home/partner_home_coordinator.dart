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

  // Fix #635: settlement 탭 전환을 home coordinator를 통해 위임 (feature 격리)
  void goToSettlement() {
    _router.go(const SettlementRoute().location);
  }

  // Fix #845: ApplicationList/Checkin 탭 전환을 coordinator를 통해 위임
  void goToApplicationList() {
    _router.go(const ApplicationListRoute().location);
  }

  void goToCheckin() {
    _router.go(const CheckinRoute().location);
  }
}
