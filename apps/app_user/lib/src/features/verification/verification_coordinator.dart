import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'verification_coordinator.g.dart';

/// **Verification Coordinator**
///
/// Handles navigation for the Verification feature in the User App.
/// Encapsulates route paths and parameter serialization logic.
@riverpod
class VerificationCoordinator extends _$VerificationCoordinator {
  @override
  void build() {}

  /// Navigates to the Verification Management page.
  ///
  /// - [partnerId]: The ID of the partner requesting verification.
  /// - [verificationIds]: List of verification requirement IDs to fulfill.
  void goToVerificationManagement(
    String partnerId,
    List<String> verificationIds,
  ) {
    // Comma-separated list for simplicity in URL
    final idsStr = verificationIds.join(',');

    final route = VerificationManagementRoute(
      partnerId: partnerId,
      verificationIds: idsStr,
    );

    unawaited(
      route.push<void>(
        ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext!,
      ),
    );
  }
}
