import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/dev/user_dev_map.dart';
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
