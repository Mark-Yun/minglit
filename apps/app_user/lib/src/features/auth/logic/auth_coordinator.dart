import 'dart:async';

import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_coordinator.g.dart';

@riverpod
AuthCoordinator authCoordinator(Ref ref) {
  return AuthCoordinator();
}

class AuthCoordinator {
  void goToLogin(BuildContext context, {String? from}) {
    unawaited(LoginRoute(from: from).push<void>(context));
  }
}
