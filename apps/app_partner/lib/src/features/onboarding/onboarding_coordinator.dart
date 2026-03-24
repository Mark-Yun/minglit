import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final onboardingCoordinatorProvider = Provider<OnboardingCoordinator>((ref) {
  return OnboardingCoordinator(ref.read(goRouterProvider));
});

/// Fix #404: Coordinator for onboarding feature navigation.
class OnboardingCoordinator {
  OnboardingCoordinator(this._router);

  final GoRouter _router;

  void goToApply() {
    _router.go(const PartnerApplyRoute().location);
  }

  void goToApplyStatus() {
    _router.go(const PartnerApplyStatusRoute().location);
  }
}
