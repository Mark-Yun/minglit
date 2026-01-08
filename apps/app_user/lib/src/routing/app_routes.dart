import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/dev/user_dev_map.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.g.dart';

/// **Dev Route**: Development Tools.
/// Path: `/dev`
@TypedGoRoute<DevRoute>(path: '/dev')
class DevRoute extends GoRouteData with $DevRoute {
  const DevRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const UserDevMap();
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
