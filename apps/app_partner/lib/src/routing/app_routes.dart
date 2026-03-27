import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/features/admin/partner_application_list_page.dart';
import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/features/home/guide/location_guide_page.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
import 'package:app_partner/src/features/more/more_page.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_status_page.dart';
import 'package:app_partner/src/features/onboarding/partner_welcome_page.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_page.dart';
import 'package:app_partner/src/features/party/detail/party_detail_page.dart';
import 'package:app_partner/src/features/party/event/create/event_create_page.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_page.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:app_partner/src/features/settlement/bank_account_page.dart';
import 'package:app_partner/src/features/settlement/settlement_detail_page.dart';
import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/features/ticket/create/ticket_create_page.dart';
import 'package:app_partner/src/features/ticket/edit/ticket_edit_page.dart';
import 'package:app_partner/src/features/verification/create/create_verification_page.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_page.dart';
import 'package:app_partner/src/ui/shell/partner_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_dev.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'app_routes.g.dart';

// --- Top Level Routes (No Shell) ---

/// **Dev User Switch Route**: Screen to switch between test users.
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

/// **Partner Apply Route**: Wizard for partner application.
@TypedGoRoute<PartnerApplyRoute>(path: '/apply')
class PartnerApplyRoute extends GoRouteData with $PartnerApplyRoute {
  const PartnerApplyRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerApplyPage();
}

/// **Partner Apply Status Route**: Application review status page.
@TypedGoRoute<PartnerApplyStatusRoute>(path: '/apply/status')
class PartnerApplyStatusRoute extends GoRouteData
    with $PartnerApplyStatusRoute {
  const PartnerApplyStatusRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerApplyStatusPage();
}

/// **Partner Welcome Route**: Onboarding page before application wizard.
@TypedGoRoute<PartnerWelcomeRoute>(path: '/welcome')
class PartnerWelcomeRoute extends GoRouteData with $PartnerWelcomeRoute {
  const PartnerWelcomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerWelcomePage();
}

/// **Notification Center Route**
/// Path: `/notifications`
@TypedGoRoute<NotificationCenterRoute>(path: '/notifications')
class NotificationCenterRoute extends GoRouteData
    with $NotificationCenterRoute {
  const NotificationCenterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationListScreen();
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
            TypedGoRoute<LocationGuideRoute>(path: 'guide/location'),
          ],
        ),
      ],
    ),
    // 2. Application Management Branch
    TypedStatefulShellBranch<ApplicationBranch>(
      routes: [
        TypedGoRoute<ApplicationListRoute>(
          path: '/applications',
          routes: [
            TypedGoRoute<ApplicationDetailRoute>(path: ':applicationId'),
          ],
        ),
      ],
    ),
    // 3. Check-in Branch
    TypedStatefulShellBranch<CheckinBranch>(
      routes: [
        TypedGoRoute<CheckinRoute>(
          path: '/checkin',
        ),
      ],
    ),
    // 4. Settlement Branch
    TypedStatefulShellBranch<SettlementBranch>(
      routes: [
        TypedGoRoute<SettlementRoute>(
          path: '/settlement',
          routes: [
            TypedGoRoute<BankAccountRoute>(path: 'bank-account'),
            TypedGoRoute<SettlementDetailRoute>(path: ':id'),
          ],
        ),
      ],
    ),
    // 5. More Branch (Party management, settings, etc.)
    TypedStatefulShellBranch<MoreBranch>(
      routes: [
        TypedGoRoute<MoreRoute>(
          path: '/more',
          routes: [
            // Party management (moved from dedicated tab)
            TypedGoRoute<PartyListRoute>(
              path: 'parties',
              routes: [
                TypedGoRoute<PartyCreateRoute>(path: 'create'),
                TypedGoRoute<PartyDetailRoute>(
                  path: ':partyId',
                  routes: [
                    TypedGoRoute<PartyEditRoute>(path: 'edit'),
                    TypedGoRoute<PartyTicketEditRoute>(
                      path: 'tickets/:ticketId/edit',
                    ),
                    TypedGoRoute<EventCreateRoute>(path: 'events/create'),
                    TypedGoRoute<EventDetailRoute>(
                      path: 'events/:eventId',
                      routes: [
                        TypedGoRoute<TicketCreateRoute>(
                          path: 'tickets/create',
                        ),
                        TypedGoRoute<TicketEditRoute>(
                          path: 'tickets/:ticketId/edit',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Settings, Profile, etc.
            TypedGoRoute<VerificationManageRoute>(path: 'verifications/manage'),
            TypedGoRoute<CreateVerificationRoute>(path: 'verifications/create'),
            TypedGoRoute<NotificationSettingsRoute>(
              path: 'notification-settings',
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

class ApplicationBranch extends StatefulShellBranchData {
  const ApplicationBranch();
}

class CheckinBranch extends StatefulShellBranchData {
  const CheckinBranch();
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

class LocationGuideRoute extends GoRouteData with $LocationGuideRoute {
  const LocationGuideRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LocationGuidePage();
}

// 2. Checkin
class CheckinRoute extends GoRouteData with $CheckinRoute {
  const CheckinRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CheckinPlaceholderPage();
}

// 3. Party (under More)
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

class PartyEditRoute extends GoRouteData with $PartyEditRoute {
  const PartyEditRoute({required this.partyId});
  final String partyId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartyCreateWizardPage(partyId: partyId);
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
      EventCreatePage(partyId: partyId);
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

class SettlementDetailRoute extends GoRouteData with $SettlementDetailRoute {
  const SettlementDetailRoute({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SettlementDetailPage(itemId: id);
}

class BankAccountRoute extends GoRouteData with $BankAccountRoute {
  const BankAccountRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BankAccountPage();
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
      const VerificationManagePage();
}

class CreateVerificationRoute extends GoRouteData
    with $CreateVerificationRoute {
  const CreateVerificationRoute({this.partnerId});
  final String? partnerId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CreateVerificationPage(partnerId: partnerId);
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

class NotificationSettingsRoute extends GoRouteData
    with $NotificationSettingsRoute {
  const NotificationSettingsRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationSettingsScreen();
}
