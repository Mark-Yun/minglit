import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/features/admin/partner_application_list_page.dart';
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/features/dev/partner_dev_map.dart';
import 'package:app_partner/src/features/event/create/event_create_page.dart';
import 'package:app_partner/src/features/event/detail/event_detail_page.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_page.dart';
import 'package:app_partner/src/features/party/detail/party_detail_page.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:app_partner/src/features/ticket/create/ticket_create_page.dart';
import 'package:app_partner/src/features/ticket/edit/ticket_edit_page.dart';
import 'package:app_partner/src/features/verification/create_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'app_routes.g.dart';

/// **Dev: Dev Map Route**
///
/// Path: `/dev`
@TypedGoRoute<DevMapRoute>(path: '/dev')
class DevMapRoute extends GoRouteData with $DevMapRoute {
  const DevMapRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerDevMap();
}

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
class CreateVerificationRoute extends GoRouteData
    with $CreateVerificationRoute {
  const CreateVerificationRoute({this.partnerId});

  final String? partnerId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CreateVerificationScreen(partnerId: partnerId);
}

/// **Party Management Routes**
///
/// Path: `/parties`
@TypedGoRoute<PartyListRoute>(
  path: '/parties',
  routes: [
    TypedGoRoute<PartyCreateRoute>(path: 'create'),
    TypedGoRoute<PartyDetailRoute>(
      path: ':partyId',
      routes: [
        TypedGoRoute<PartyTicketEditRoute>(path: 'tickets/:ticketId/edit'),
        TypedGoRoute<EventCreateRoute>(path: 'events/create'),
        TypedGoRoute<EventDetailRoute>(
          path: 'events/:eventId',
          routes: [
            TypedGoRoute<TicketCreateRoute>(path: 'tickets/create'),
            TypedGoRoute<TicketEditRoute>(path: 'tickets/:ticketId/edit'),
          ],
        ),
      ],
    ),
  ],
)
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
  const PartyTicketEditRoute({
    required this.partyId,
    required this.ticketId,
  });

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
  const TicketCreateRoute({
    required this.partyId,
    required this.eventId,
  });

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
