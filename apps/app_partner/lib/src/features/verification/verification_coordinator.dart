import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verification_coordinator.g.dart';

@riverpod
class VerificationCoordinator extends _$VerificationCoordinator {
  @override
  void build() {}

  void pushVerificationManage() {
    unawaited(
      ref.read(goRouterProvider).push(const VerificationManageRoute().location),
    );
  }

  void pushCreateVerification({String? partnerId}) {
    unawaited(
      ref
          .read(goRouterProvider)
          .push(
            CreateVerificationRoute(partnerId: partnerId).location,
          ),
    );
  }
}
