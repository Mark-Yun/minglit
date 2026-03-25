import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_coordinator.g.dart';

@riverpod
AuthCoordinator authCoordinator(Ref ref) {
  return AuthCoordinator(ref.read(goRouterProvider));
}

class AuthCoordinator {
  AuthCoordinator(this._router);

  final GoRouter _router;

  void pushLogin({String? from}) {
    unawaited(_router.push(LoginRoute(from: from).location));
  }

  void goToLogin({String? from}) {
    _router.go(LoginRoute(from: from).location);
  }

  void goToReturnLocation(String location) {
    _router.go(location);
  }

  // Fix #404: Coordinator-based navigation for home route
  void goToHome() {
    _router.go('/');
  }

  void pushDevUserSwitch() {
    unawaited(_router.push(const DevUserSwitchRoute().location));
  }
}
