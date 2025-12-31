import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/features/admin/partner_application_list_page.dart';
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
import 'package:app_partner/src/features/verification/create_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'app_routes.g.dart';

/// **Dev: User Switch Route**
///
/// Path: `/dev/user-switch`
@TypedGoRoute<DevUserSwitchRoute>(path: '/dev/user-switch')
class DevUserSwitchRoute extends GoRouteData with $DevUserSwitchRoute {
  const DevUserSwitchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DevUserSwitchScreen();
}

/// **Verification: Create Verification Route**
///
/// Path: `/verifications/create`
@TypedGoRoute<CreateVerificationRoute>(path: '/verifications/create')
class CreateVerificationRoute extends GoRouteData with $CreateVerificationRoute {
  const CreateVerificationRoute({this.partnerId});

  final String? partnerId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CreateVerificationScreen(partnerId: partnerId);
}

/// **Auth Route**: Login Screen.
///
/// Path: `/login`
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerLoginPage();
}

/// **Home Route**: Main Dashboard.
///
/// Path: `/`
/// This is the landing page for authenticated users.
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerHomePage();
}

/// **Admin: Application List Route**
///
/// Path: `/admin/applications`
@TypedGoRoute<ApplicationListRoute>(
  path: '/admin/applications',
  routes: [
    TypedGoRoute<ApplicationDetailRoute>(path: ':applicationId'),
  ],
)
class ApplicationListRoute extends GoRouteData with $ApplicationListRoute {
  const ApplicationListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerApplicationListPage();
}

/// **Admin: Application Detail Route**
///
/// Path: `/admin/applications/:applicationId`
class ApplicationDetailRoute extends GoRouteData with $ApplicationDetailRoute {
  const ApplicationDetailRoute({required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PartnerApplicationDetailPage(applicationId: applicationId);
  }
}

/// **Member List Route**: Manage partner staff and their permissions.
///
/// Path: `/partners/:partnerId/members`
///
/// - [partnerId]: The ID of the partner organization.
@TypedGoRoute<MemberListRoute>(
  path: '/partners/:partnerId/members',
  routes: [
    TypedGoRoute<MemberPermissionRoute>(path: ':targetUserId/permission'),
  ],
)
class MemberListRoute extends GoRouteData with $MemberListRoute {
  const MemberListRoute({required this.partnerId});

  final String partnerId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartnerMemberListPage(partnerId: partnerId);
}

/// **Member Permission Route**:
/// Detail view for editing a specific member's role.
///
/// Path: `/partners/:partnerId/members/:targetUserId/permission`
///
/// - [partnerId]: Context of the organization.
/// - [targetUserId]: The ID of the member to edit.
class MemberPermissionRoute extends GoRouteData with $MemberPermissionRoute {
  const MemberPermissionRoute({
    required this.partnerId,
    required this.targetUserId,
  });

  final String partnerId;
  final String targetUserId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PartnerMemberPermissionPage(
      partnerId: partnerId,
      targetUserId: targetUserId,
    );
  }
}
