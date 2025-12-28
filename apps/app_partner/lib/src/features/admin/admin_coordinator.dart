import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_coordinator.g.dart';

@riverpod
class AdminCoordinator extends _$AdminCoordinator {
  @override
  void build() {}

  void goToApplicationDetail(String applicationId) {
    final route = ApplicationDetailRoute(applicationId: applicationId);
    unawaited(
      route.push<void>(
        ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext!,
      ),
    );
  }
}
