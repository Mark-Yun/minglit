import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/auth/ui/auth_callback_page.dart';
import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:app_user/src/features/event/admission/event_application_wizard_page.dart';
import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/features/my_tickets/ui/my_tickets_page.dart';
import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/detail/partner_events_page.dart';
import 'package:app_user/src/features/party/party_curation_page.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:app_user/src/features/ticket/ui/ticket_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_dev.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'app_routes.g.dart';

// ---------------------------------------------------------------------------
// Top-Level Routes (outside the shell)
// ---------------------------------------------------------------------------

/// **Dev User Switch Route**: Screen to switch between test users.
/// Path: `/dev/switch`
@TypedGoRoute<DevUserSwitchRoute>(path: '/dev/switch')
class DevUserSwitchRoute extends GoRouteData with $DevUserSwitchRoute {
  const DevUserSwitchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DevUserSwitchScreen();
}

/// **Auth Route**: Login Screen.
/// Path: `/login`
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute({this.from});

  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LoginPage(from: from);
}

/// **Signup Consent Route**: Required consent collection screen.
/// Path: `/signup/consent`
@TypedGoRoute<SignupConsentRoute>(path: '/signup/consent')
class SignupConsentRoute extends GoRouteData with $SignupConsentRoute {
  const SignupConsentRoute({this.from});

  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SignupConsentPage(from: from);
}

/// **Auth Callback Route**: Handles OAuth redirects.
/// Path: `/auth/callback`
@TypedGoRoute<AuthCallbackRoute>(path: '/auth/callback')
class AuthCallbackRoute extends GoRouteData with $AuthCallbackRoute {
  const AuthCallbackRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AuthCallbackPage();
}

/// **Event Detail Route**: Detailed information about a specific event.
/// Path: `/events/:eventId`
@TypedGoRoute<EventDetailRoute>(path: '/events/:eventId')
class EventDetailRoute extends GoRouteData with $EventDetailRoute {
  const EventDetailRoute({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EventDetailPage(eventId: eventId);
}

/// **Partner Detail Route**: Detailed information about a specific partner.
/// Path: `/partners/:partnerId`
@TypedGoRoute<PartnerDetailRoute>(path: '/partners/:partnerId')
class PartnerDetailRoute extends GoRouteData with $PartnerDetailRoute {
  const PartnerDetailRoute({required this.partnerId});

  final String partnerId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartnerDetailPage(partnerId: partnerId);
}

/// **Partner Events Route**: Full list of events for a partner.
/// Path: `/partners/:partnerId/events`
@TypedGoRoute<PartnerEventsRoute>(path: '/partners/:partnerId/events')
class PartnerEventsRoute extends GoRouteData with $PartnerEventsRoute {
  const PartnerEventsRoute({
    required this.partnerId,
    required this.partnerName,
  });

  final String partnerId;
  final String partnerName;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartnerEventsPage(partnerId: partnerId, partnerName: partnerName);
}

/// **Certification Route**: Identity Verification Screen.
/// Path: `/certification`
@TypedGoRoute<CertificationRoute>(path: '/certification')
class CertificationRoute extends GoRouteData with $CertificationRoute {
  const CertificationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const IdentityVerificationScreen();
  }
}

/// **Event Application Route**: Wizard for event application.
/// Path: `/events/:eventId/apply`
@TypedGoRoute<EventApplicationRoute>(path: '/events/:eventId/apply')
class EventApplicationRoute extends GoRouteData with $EventApplicationRoute {
  const EventApplicationRoute({required this.eventId, this.ticketId});

  final String eventId;
  final String? ticketId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EventApplicationWizardPage(eventId: eventId, ticketId: ticketId);
}

/// **My Tickets Route**: User's ticket list page.
/// Path: `/tickets/my`
@TypedGoRoute<MyTicketsRoute>(path: '/tickets/my')
class MyTicketsRoute extends GoRouteData with $MyTicketsRoute {
  const MyTicketsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MyTicketsPage();
}

/// **Ticket QR Route**: QR code screen for a specific ticket.
/// Path: `/tickets/:ticketId/qr`
@TypedGoRoute<TicketQRRoute>(path: '/tickets/:ticketId/qr')
class TicketQRRoute extends GoRouteData with $TicketQRRoute {
  const TicketQRRoute({required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TicketQRScreen(ticketId: ticketId);
}

/// **Purchase History Route**
/// Path: `/purchase-history`
@TypedGoRoute<PurchaseHistoryRoute>(path: '/purchase-history')
class PurchaseHistoryRoute extends GoRouteData with $PurchaseHistoryRoute {
  const PurchaseHistoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PurchaseHistoryPage();
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

/// **Notification Settings Route**
/// Path: `/my/notification-settings`
@TypedGoRoute<NotificationSettingsRoute>(path: '/my/notification-settings')
class NotificationSettingsRoute extends GoRouteData
    with $NotificationSettingsRoute {
  const NotificationSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationSettingsScreen();
}

// ---------------------------------------------------------------------------
// Shell Routes (promoted to top-level)
// ---------------------------------------------------------------------------

/// **Home Route**: Main Dashboard.
/// Path: `/`
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [TypedGoRoute<EventCurationRoute>(path: 'curation')],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// **Event Curation Route**: Paginated curation list.
/// Path: `/explore/curation`
class EventCurationRoute extends GoRouteData with $EventCurationRoute {
  const EventCurationRoute({this.type = EventFeedType.newArrivals});

  final EventFeedType type;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartyCurationPage(type: type);
}

/// **Search Route**: Full-page search screen.
/// Path: `/search`
@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData with $SearchRoute {
  const SearchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SearchPage();
}

/// **My Page Route**
/// Path: `/my`
@TypedGoRoute<MyPageRoute>(path: '/my')
class MyPageRoute extends GoRouteData with $MyPageRoute {
  const MyPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MyPage();
}

/// **Privacy Route**: Privacy settings page.
/// Path: `/my/privacy`
@TypedGoRoute<PrivacyRoute>(path: '/my/privacy')
class PrivacyRoute extends GoRouteData with $PrivacyRoute {
  const PrivacyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrivacyPage();
}

/// **Deletion Reason Route**: Account deletion reason selection page.
/// Path: `/my/privacy/delete/reason`
@TypedGoRoute<DeletionReasonRoute>(path: '/my/privacy/delete/reason')
class DeletionReasonRoute extends GoRouteData with $DeletionReasonRoute {
  const DeletionReasonRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DeletionReasonPage();
}

/// **Deletion Info Route**: Account deletion 안내 page.
/// Path: `/my/privacy/delete/info`
@TypedGoRoute<DeletionInfoRoute>(path: '/my/privacy/delete/info')
class DeletionInfoRoute extends GoRouteData with $DeletionInfoRoute {
  const DeletionInfoRoute({this.reasonCode, this.reasonText});

  final String? reasonCode;
  final String? reasonText;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DeletionInfoPage(reasonCode: reasonCode, reasonText: reasonText);
}

/// **Deletion Verify Route**: Account deletion verification page.
/// Path: `/my/privacy/delete/verify`
@TypedGoRoute<DeletionVerifyRoute>(path: '/my/privacy/delete/verify')
class DeletionVerifyRoute extends GoRouteData with $DeletionVerifyRoute {
  const DeletionVerifyRoute({this.reasonCode, this.reasonText});

  final String? reasonCode;
  final String? reasonText;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DeletionVerifyPage(reasonCode: reasonCode, reasonText: reasonText);
}

/// **Deletion Complete Route**: Account deletion completion page.
/// Path: `/my/privacy/delete/complete`
@TypedGoRoute<DeletionCompleteRoute>(path: '/my/privacy/delete/complete')
class DeletionCompleteRoute extends GoRouteData with $DeletionCompleteRoute {
  const DeletionCompleteRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DeletionCompletePage();
}

/// **Blocked Partners Route**: Blocked partners list page.
/// Path: `/my/blocked-partners`
@TypedGoRoute<BlockedPartnersRoute>(path: '/my/blocked-partners')
class BlockedPartnersRoute extends GoRouteData with $BlockedPartnersRoute {
  const BlockedPartnersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BlockedPartnersPage();
}
