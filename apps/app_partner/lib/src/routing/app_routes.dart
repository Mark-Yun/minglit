import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/features/admin/partner_application_list_page.dart';
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/features/dev/partner_dev_map.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
import 'package:app_partner/src/features/more/more_page.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_page.dart';
import 'package:app_partner/src/features/party/detail/party_detail_page.dart';
import 'package:app_partner/src/features/party/event/create/event_create_screen.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_page.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/features/ticket/create/ticket_create_page.dart';
import 'package:app_partner/src/features/ticket/edit/ticket_edit_page.dart';
import 'package:app_partner/src/features/verification/create/create_verification_screen.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_screen.dart';
import 'package:app_partner/src/ui/shell/partner_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'app_routes.g.dart';

// --- Top Level Routes (No Shell) ---

/// **Dev: Dev Map Route**
@TypedGoRoute<DevMapRoute>(path: '/dev')
class DevMapRoute extends GoRouteData with $DevMapRoute {
  const DevMapRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerDevMap();
}

@TypedGoRoute<DevUserSwitchRoute>(path: '/dev/user-switch')
class DevUserSwitchRoute extends GoRouteData with $DevUserSwitchRoute {
  const DevUserSwitchRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DevUserSwitchScreen();
}

/// **Auth Route**: Login Screen.
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerLoginPage();
}

// --- Stateful Shell Route (Bottom Navigation) ---

@TypedStatefulShellRoute<PartnerShellRoute>(
  branches: [
    // 1. Home Branch
    TypedStatefulShellBranch<HomeBranch>(
      routes: [
        TypedGoRoute<HomeRoute>(
          path: '/',
          routes: [
            // Sub-routes accessible from Home
            TypedGoRoute<ApplicationListRoute>(
              path: 'applications',
              routes: [
                TypedGoRoute<ApplicationDetailRoute>(path: ':applicationId'),
              ],
            ),
          ],
        ),
      ],
    ),
    // 2. Party Branch
    TypedStatefulShellBranch<PartyBranch>(
      routes: [
        TypedGoRoute<PartyListRoute>(
          path: '/parties',
          routes: [
            TypedGoRoute<PartyCreateRoute>(path: 'create'),
            TypedGoRoute<PartyDetailRoute>(
              path: ':partyId',
              routes: [
                TypedGoRoute<PartyTicketEditRoute>(
                  path: 'tickets/:ticketId/edit',
                ),
                TypedGoRoute<EventCreateRoute>(path: 'events/create'),
                TypedGoRoute<EventDetailRoute>(
                  path: 'events/:eventId',
                  routes: [
                    TypedGoRoute<TicketCreateRoute>(path: 'tickets/create'),
                    TypedGoRoute<TicketEditRoute>(
                      path: 'tickets/:ticketId/edit',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // 3. Settlement Branch
    TypedStatefulShellBranch<SettlementBranch>(
      routes: [
        TypedGoRoute<SettlementRoute>(path: '/settlement'),
      ],
    ),
    // 4. More Branch
    TypedStatefulShellBranch<MoreBranch>(
      routes: [
        TypedGoRoute<MoreRoute>(
          path: '/more',
          routes: [
            // Settings, Profile, etc.
            TypedGoRoute<VerificationManageRoute>(
              path: 'verifications/manage',
            ),
            TypedGoRoute<CreateVerificationRoute>(
              path: 'verifications/create',
            ),
            TypedGoRoute<MemberListRoute>(
              path: 'partners/:partnerId/members',
              routes: [
                TypedGoRoute<MemberPermissionRoute>(
                  path: ':targetUserId/permission',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
)
class PartnerShellRoute extends StatefulShellRouteData {
  const PartnerShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return PartnerScaffold(navigationShell: navigationShell);
  }
}

// --- Branches ---

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
}

class PartyBranch extends StatefulShellBranchData {
  const PartyBranch();
}

class SettlementBranch extends StatefulShellBranchData {
  const SettlementBranch();
}

class MoreBranch extends StatefulShellBranchData {
  const MoreBranch();
}

// --- Route Data Classes ---

// 1. Home
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerHomePage();
}

class ApplicationListRoute extends GoRouteData with $ApplicationListRoute {
  const ApplicationListRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerApplicationListPage();
}

class ApplicationDetailRoute extends GoRouteData with $ApplicationDetailRoute {
  const ApplicationDetailRoute({required this.applicationId});
  final String applicationId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartnerApplicationDetailPage(applicationId: applicationId);
}

// 2. Party
class PartyListRoute extends GoRouteData with $PartyListRoute {
  const PartyListRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartyListPage();
}

class PartyCreateRoute extends GoRouteData with $PartyCreateRoute {
  const PartyCreateRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartyCreateWizardPage();
}

class PartyDetailRoute extends GoRouteData with $PartyDetailRoute {
  const PartyDetailRoute({required this.partyId});
  final String partyId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartyDetailPage(partyId: partyId);
}

class PartyTicketEditRoute extends GoRouteData with $PartyTicketEditRoute {
  const PartyTicketEditRoute({required this.partyId, required this.ticketId});
  final String partyId;
  final String ticketId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TicketEditPage(partyId: partyId, eventId: '', ticketId: ticketId);
}

class EventCreateRoute extends GoRouteData with $EventCreateRoute {
  const EventCreateRoute({required this.partyId});
  final String partyId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EventCreateScreen(partyId: partyId);
}

class EventDetailRoute extends GoRouteData with $EventDetailRoute {
  const EventDetailRoute({required this.partyId, required this.eventId});
  final String partyId;
  final String eventId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EventDetailPage(eventId: eventId);
}

class TicketCreateRoute extends GoRouteData with $TicketCreateRoute {
  const TicketCreateRoute({required this.partyId, required this.eventId});
  final String partyId;
  final String eventId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TicketCreatePage(partyId: partyId, eventId: eventId);
}

class TicketEditRoute extends GoRouteData with $TicketEditRoute {
  const TicketEditRoute({
    required this.partyId,
    required this.eventId,
    required this.ticketId,
  });
  final String partyId;
  final String eventId;
  final String ticketId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TicketEditPage(partyId: partyId, eventId: eventId, ticketId: ticketId);
}

// 3. Settlement
class SettlementRoute extends GoRouteData with $SettlementRoute {
  const SettlementRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettlementPage();
}

// 4. More
class MoreRoute extends GoRouteData with $MoreRoute {
  const MoreRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const MorePage();
}

class VerificationManageRoute extends GoRouteData
    with $VerificationManageRoute {
  const VerificationManageRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const VerificationManageScreen();
}

class CreateVerificationRoute extends GoRouteData
    with $CreateVerificationRoute {
  const CreateVerificationRoute({this.partnerId});
  final String? partnerId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CreateVerificationScreen(partnerId: partnerId);
}

class MemberListRoute extends GoRouteData with $MemberListRoute {
  const MemberListRoute({required this.partnerId});
  final String partnerId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartnerMemberListPage(partnerId: partnerId);
}

class MemberPermissionRoute extends GoRouteData with $MemberPermissionRoute {
  const MemberPermissionRoute({
    required this.partnerId,
    required this.targetUserId,
  });
  final String partnerId;
  final String targetUserId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartnerMemberPermissionPage(
        partnerId: partnerId,
        targetUserId: targetUserId,
      );
}
