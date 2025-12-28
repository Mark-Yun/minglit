import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/verification/verification_inbox_page.dart';
import 'package:app_user/src/features/verification/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.g.dart';

/// **Auth Route**: Login Screen.
/// Path: `/login`
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginPage();
}

/// **Home Route**: Main Dashboard.
/// Path: `/`
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// **Verification Inbox Route**: List of notifications/requests.
/// Path: `/verification/inbox`
@TypedGoRoute<VerificationInboxRoute>(
  path: '/verification/inbox',
  routes: [
    TypedGoRoute<VerificationManagementRoute>(path: 'management/:partnerId'),
  ],
)
class VerificationInboxRoute extends GoRouteData with $VerificationInboxRoute {
  const VerificationInboxRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const VerificationInboxPage();
}

/// **Verification Management Route**: Detail view for submitting verifications.
/// Path: `/verification/inbox/management/:partnerId`
class VerificationManagementRoute extends GoRouteData
    with $VerificationManagementRoute {
  const VerificationManagementRoute({
    required this.partnerId,
    required this.verificationIds,
  });

  final String partnerId;

  /// Comma-separated list of verification IDs.
  final String verificationIds;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final ids = verificationIds.split(',');
    return VerificationManagementPage(
      partnerId: partnerId,
      requiredVerificationIds: ids,
    );
  }
}
