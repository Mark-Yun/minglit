import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/auth/ui/auth_callback_screen.dart';
import 'package:app_user/src/features/dev/user_dev_map.dart';
import 'package:app_user/src/features/event/admission/event_application_wizard_screen.dart';
import 'package:app_user/src/features/event/detail/event_detail_screen.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/party/party_curation_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'app_routes.g.dart';

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
      const AuthCallbackScreen();
}

/// **Home Route**: Main Dashboard.
/// Path: `/`
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// **Event Curation Route**: Paginated curation list.
/// Path: `/curation`
@TypedGoRoute<EventCurationRoute>(path: '/curation')
class EventCurationRoute extends GoRouteData with $EventCurationRoute {
  const EventCurationRoute({this.type = EventFeedType.newArrivals});

  final EventFeedType type;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartyCurationScreen(type: type);
}

/// **Event Detail Route**: Detailed information about a specific event.
/// Path: `/events/:eventId`
@TypedGoRoute<EventDetailRoute>(path: '/events/:eventId')
class EventDetailRoute extends GoRouteData with $EventDetailRoute {
  const EventDetailRoute({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EventDetailScreen(eventId: eventId);
}

/// **Certification Route**: Identity Verification Screen.
/// Path: `/certification`
@TypedGoRoute<CertificationRoute>(path: '/certification')
class CertificationRoute extends GoRouteData with $CertificationRoute {
  const CertificationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MinglitIamportCertification(
      onSuccess: (uid) {
        Log.i('Certification Success: $uid');
        context.pop();
        context.showMinglitSuccess('인증 성공! UID: $uid');
      },
      onFail: (msg) {
        Log.e('Certification Failed: $msg');
        context.pop();
        context.showMinglitWarning('인증 실패: $msg');
      },
    );
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
      EventApplicationWizardScreen(eventId: eventId, ticketId: ticketId);
}
