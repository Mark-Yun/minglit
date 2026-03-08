import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final homeCoordinatorProvider = Provider<HomeCoordinator>((ref) {
  return HomeCoordinator(ref.read(goRouterProvider));
});

class HomeCoordinator {
  HomeCoordinator(this._router);

  final GoRouter _router;

  void pushNotificationCenter() {
    unawaited(_router.push(const NotificationCenterRoute().location));
  }

  void pushPurchaseHistory() {
    unawaited(_router.push(const PurchaseHistoryRoute().location));
  }

  void goToPurchaseHistory() {
    _router.go(const PurchaseHistoryRoute().location);
  }

  void pushNotificationSettings() {
    unawaited(_router.push(const NotificationSettingsRoute().location));
  }
}
