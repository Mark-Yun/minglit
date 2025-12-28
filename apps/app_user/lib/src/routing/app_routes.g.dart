// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $loginRoute,
  $homeRoute,
  $verificationInboxRoute,
];

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

RouteBase get $verificationInboxRoute => GoRouteData.$route(
  path: '/verification/inbox',
  factory: $VerificationInboxRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'management/:partnerId',
      factory: $VerificationManagementRoute._fromState,
    ),
  ],
);

mixin $VerificationInboxRoute on GoRouteData {
  static VerificationInboxRoute _fromState(GoRouterState state) =>
      const VerificationInboxRoute();

  @override
  String get location => GoRouteData.$location('/verification/inbox');

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

mixin $VerificationManagementRoute on GoRouteData {
  static VerificationManagementRoute _fromState(GoRouterState state) =>
      VerificationManagementRoute(
        partnerId: state.pathParameters['partnerId']!,
        verificationIds: state.uri.queryParameters['verification-ids']!,
      );

  VerificationManagementRoute get _self => this as VerificationManagementRoute;

  @override
  String get location => GoRouteData.$location(
    '/verification/inbox/management/${Uri.encodeComponent(_self.partnerId)}',
    queryParams: {'verification-ids': _self.verificationIds},
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
