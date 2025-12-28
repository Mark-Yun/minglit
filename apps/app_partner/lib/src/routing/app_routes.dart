
import 'package:app_partner/main.dart';
import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.g.dart';

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

/// **Member Permission Route**: Detail view for editing a specific member's role.
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

