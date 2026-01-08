// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $devMapRoute,
  $devUserSwitchRoute,
  $createVerificationRoute,
  $partyListRoute,
  $loginRoute,
  $homeRoute,
  $applicationListRoute,
  $memberListRoute,
];

RouteBase get $devMapRoute =>
    GoRouteData.$route(path: '/dev', factory: $DevMapRoute._fromState);

mixin $DevMapRoute on GoRouteData {
  static DevMapRoute _fromState(GoRouterState state) => const DevMapRoute();

  @override
  String get location => GoRouteData.$location('/dev');

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

RouteBase get $createVerificationRoute => GoRouteData.$route(
  path: '/verifications/create',
  factory: $CreateVerificationRoute._fromState,
);

mixin $CreateVerificationRoute on GoRouteData {
  static CreateVerificationRoute _fromState(GoRouterState state) =>
      CreateVerificationRoute(
        partnerId: state.uri.queryParameters['partner-id'],
      );

  CreateVerificationRoute get _self => this as CreateVerificationRoute;

  @override
  String get location => GoRouteData.$location(
    '/verifications/create',
    queryParams: {if (_self.partnerId != null) 'partner-id': _self.partnerId},
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

RouteBase get $partyListRoute => GoRouteData.$route(
  path: '/parties',
  factory: $PartyListRoute._fromState,
  routes: [
    GoRouteData.$route(path: 'create', factory: $PartyCreateRoute._fromState),
    GoRouteData.$route(
      path: ':partyId',
      factory: $PartyDetailRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'tickets/:ticketId/edit',
          factory: $PartyTicketEditRoute._fromState,
        ),
        GoRouteData.$route(
          path: 'events/create',
          factory: $EventCreateRoute._fromState,
        ),
        GoRouteData.$route(
          path: 'events/:eventId',
          factory: $EventDetailRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'tickets/create',
              factory: $TicketCreateRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'tickets/:ticketId/edit',
              factory: $TicketEditRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

mixin $PartyListRoute on GoRouteData {
  static PartyListRoute _fromState(GoRouterState state) =>
      const PartyListRoute();

  @override
  String get location => GoRouteData.$location('/parties');

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

mixin $PartyCreateRoute on GoRouteData {
  static PartyCreateRoute _fromState(GoRouterState state) =>
      const PartyCreateRoute();

  @override
  String get location => GoRouteData.$location('/parties/create');

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

mixin $PartyDetailRoute on GoRouteData {
  static PartyDetailRoute _fromState(GoRouterState state) =>
      PartyDetailRoute(partyId: state.pathParameters['partyId']!);

  PartyDetailRoute get _self => this as PartyDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/parties/${Uri.encodeComponent(_self.partyId)}');

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

mixin $PartyTicketEditRoute on GoRouteData {
  static PartyTicketEditRoute _fromState(GoRouterState state) =>
      PartyTicketEditRoute(
        partyId: state.pathParameters['partyId']!,
        ticketId: state.pathParameters['ticketId']!,
      );

  PartyTicketEditRoute get _self => this as PartyTicketEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/parties/${Uri.encodeComponent(_self.partyId)}/tickets/${Uri.encodeComponent(_self.ticketId)}/edit',
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

mixin $EventCreateRoute on GoRouteData {
  static EventCreateRoute _fromState(GoRouterState state) =>
      EventCreateRoute(partyId: state.pathParameters['partyId']!);

  EventCreateRoute get _self => this as EventCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/parties/${Uri.encodeComponent(_self.partyId)}/events/create',
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

mixin $EventDetailRoute on GoRouteData {
  static EventDetailRoute _fromState(GoRouterState state) => EventDetailRoute(
    partyId: state.pathParameters['partyId']!,
    eventId: state.pathParameters['eventId']!,
  );

  EventDetailRoute get _self => this as EventDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/parties/${Uri.encodeComponent(_self.partyId)}/events/${Uri.encodeComponent(_self.eventId)}',
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

mixin $TicketCreateRoute on GoRouteData {
  static TicketCreateRoute _fromState(GoRouterState state) => TicketCreateRoute(
    partyId: state.pathParameters['partyId']!,
    eventId: state.pathParameters['eventId']!,
  );

  TicketCreateRoute get _self => this as TicketCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/parties/${Uri.encodeComponent(_self.partyId)}/events/${Uri.encodeComponent(_self.eventId)}/tickets/create',
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

mixin $TicketEditRoute on GoRouteData {
  static TicketEditRoute _fromState(GoRouterState state) => TicketEditRoute(
    partyId: state.pathParameters['partyId']!,
    eventId: state.pathParameters['eventId']!,
    ticketId: state.pathParameters['ticketId']!,
  );

  TicketEditRoute get _self => this as TicketEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/parties/${Uri.encodeComponent(_self.partyId)}/events/${Uri.encodeComponent(_self.eventId)}/tickets/${Uri.encodeComponent(_self.ticketId)}/edit',
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
