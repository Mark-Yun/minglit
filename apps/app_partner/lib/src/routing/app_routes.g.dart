// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $devUserSwitchRoute,
  $loginRoute,
  $homeRoute,
  $applicationListRoute,
  $memberListRoute,
];

RouteBase get $devUserSwitchRoute => GoRouteData.$route(
  path: '/dev/user-switch',
  factory: $DevUserSwitchRoute._fromState,
);

mixin $DevUserSwitchRoute on GoRouteData {
  static DevUserSwitchRoute _fromState(GoRouterState state) =>
      const DevUserSwitchRoute();

  @override
  String get location => GoRouteData.$location('/dev/user-switch');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute =>
    GoRouteData.$route(path: '/login', factory: $LoginRoute._fromState);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $homeRoute =>
    GoRouteData.$route(path: '/', factory: $HomeRoute._fromState);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $applicationListRoute => GoRouteData.$route(
  path: '/admin/applications',
  factory: $ApplicationListRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: ':applicationId',
      factory: $ApplicationDetailRoute._fromState,
    ),
  ],
);

mixin $ApplicationListRoute on GoRouteData {
  static ApplicationListRoute _fromState(GoRouterState state) =>
      const ApplicationListRoute();

  @override
  String get location => GoRouteData.$location('/admin/applications');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ApplicationDetailRoute on GoRouteData {
  static ApplicationDetailRoute _fromState(GoRouterState state) =>
      ApplicationDetailRoute(
        applicationId: state.pathParameters['applicationId']!,
      );

  ApplicationDetailRoute get _self => this as ApplicationDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/admin/applications/${Uri.encodeComponent(_self.applicationId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $memberListRoute => GoRouteData.$route(
  path: '/partners/:partnerId/members',
  factory: $MemberListRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: ':targetUserId/permission',
      factory: $MemberPermissionRoute._fromState,
    ),
  ],
);

mixin $MemberListRoute on GoRouteData {
  static MemberListRoute _fromState(GoRouterState state) =>
      MemberListRoute(partnerId: state.pathParameters['partnerId']!);

  MemberListRoute get _self => this as MemberListRoute;

  @override
  String get location => GoRouteData.$location(
    '/partners/${Uri.encodeComponent(_self.partnerId)}/members',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MemberPermissionRoute on GoRouteData {
  static MemberPermissionRoute _fromState(GoRouterState state) =>
      MemberPermissionRoute(
        partnerId: state.pathParameters['partnerId']!,
        targetUserId: state.pathParameters['targetUserId']!,
      );

  MemberPermissionRoute get _self => this as MemberPermissionRoute;

  @override
  String get location => GoRouteData.$location(
    '/partners/${Uri.encodeComponent(_self.partnerId)}/members/${Uri.encodeComponent(_self.targetUserId)}/permission',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
