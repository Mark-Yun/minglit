import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/auth/ui/auth_callback_page.dart';
import 'package:app_user/src/features/dev/user_dev_map.dart';
import 'package:app_user/src/features/event/admission/event_application_wizard_page.dart';
import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/party/party_curation_page.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_dev.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'app_routes.g.dart';

// ---------------------------------------------------------------------------
// Top-Level Routes (outside the shell)
// ---------------------------------------------------------------------------

/// **Dev Route**: Development Tools.
/// Path: `/dev`
@TypedGoRoute<DevRoute>(path: '/dev')
class DevRoute extends GoRouteData with $DevRoute {
  const DevRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const UserDevMap();
}

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
