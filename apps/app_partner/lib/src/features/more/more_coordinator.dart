import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final moreCoordinatorProvider = Provider<MoreCoordinator>((ref) {
  return MoreCoordinator(ref.read(goRouterProvider));
});

class MoreCoordinator {
  MoreCoordinator(this._router);

  final GoRouter _router;

  void pushNotificationSettings() {
    unawaited(_router.push(const NotificationSettingsRoute().location));
  }

  void pushMemberList(String partnerId) {
    unawaited(_router.push(MemberListRoute(partnerId: partnerId).location));
  }

  void pushVerificationManage() {
    unawaited(_router.push(const VerificationManageRoute().location));
  }

  void pushAccountDeletion() {
    unawaited(_router.push(const DeletionReasonRoute().location));
  }

  // Fix #404: Coordinator-based navigation for home route (logout)
  void goToHome() {
    _router.go('/');
  }
}
