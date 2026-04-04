// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $devUserSwitchRoute,
  $loginRoute,
  $partnerApplyRoute,
  $partnerApplyStatusRoute,
  $partnerWelcomeRoute,
  $notificationCenterRoute,
  $partnerShellRoute,
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

RouteBase get $partnerApplyRoute =>
    GoRouteData.$route(path: '/apply', factory: $PartnerApplyRoute._fromState);

mixin $PartnerApplyRoute on GoRouteData {
  static PartnerApplyRoute _fromState(GoRouterState state) =>
      const PartnerApplyRoute();

  @override
  String get location => GoRouteData.$location('/apply');

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

RouteBase get $partnerApplyStatusRoute => GoRouteData.$route(
  path: '/apply/status',
  factory: $PartnerApplyStatusRoute._fromState,
);

mixin $PartnerApplyStatusRoute on GoRouteData {
  static PartnerApplyStatusRoute _fromState(GoRouterState state) =>
      const PartnerApplyStatusRoute();

  @override
  String get location => GoRouteData.$location('/apply/status');

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

RouteBase get $partnerWelcomeRoute => GoRouteData.$route(
  path: '/welcome',
  factory: $PartnerWelcomeRoute._fromState,
);

mixin $PartnerWelcomeRoute on GoRouteData {
  static PartnerWelcomeRoute _fromState(GoRouterState state) =>
      const PartnerWelcomeRoute();

  @override
  String get location => GoRouteData.$location('/welcome');

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

RouteBase get $notificationCenterRoute => GoRouteData.$route(
  path: '/notifications',
  factory: $NotificationCenterRoute._fromState,
);

mixin $NotificationCenterRoute on GoRouteData {
  static NotificationCenterRoute _fromState(GoRouterState state) =>
      const NotificationCenterRoute();

  @override
  String get location => GoRouteData.$location('/notifications');

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

RouteBase get $partnerShellRoute => StatefulShellRouteData.$route(
  factory: $PartnerShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/',
          factory: $HomeRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'guide/location',
              factory: $LocationGuideRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/applications',
          factory: $ApplicationListRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':applicationId',
              factory: $ApplicationDetailRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(path: '/checkin', factory: $CheckinRoute._fromState),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/settlement',
          factory: $SettlementRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'bank-account',
              factory: $BankAccountRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':id',
              factory: $SettlementDetailRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/more',
          factory: $MoreRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'parties',
              factory: $PartyListRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'create',
                  factory: $PartyCreateRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':partyId',
                  factory: $PartyDetailRoute._fromState,
                  routes: [
                    GoRouteData.$route(
                      path: 'edit',
                      factory: $PartyEditRoute._fromState,
                    ),
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
            ),
            GoRouteData.$route(
              path: 'verifications/manage',
              factory: $VerificationManageRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'verifications/create',
              factory: $CreateVerificationRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'notification-settings',
              factory: $NotificationSettingsRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'delete-account',
              factory: $DeletionReasonRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'delete-account/info',
              factory: $DeletionInfoRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'delete-account/verify',
              factory: $DeletionVerifyRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'delete-account/complete',
              factory: $DeletionCompleteRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'partners/:partnerId/members',
              factory: $MemberListRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: ':targetUserId/permission',
                  factory: $MemberPermissionRoute._fromState,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $PartnerShellRouteExtension on PartnerShellRoute {
  static PartnerShellRoute _fromState(GoRouterState state) =>
      const PartnerShellRoute();
}

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

mixin $LocationGuideRoute on GoRouteData {
  static LocationGuideRoute _fromState(GoRouterState state) =>
      const LocationGuideRoute();

  @override
  String get location => GoRouteData.$location('/guide/location');

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

mixin $ApplicationListRoute on GoRouteData {
  static ApplicationListRoute _fromState(GoRouterState state) =>
      const ApplicationListRoute();

  @override
  String get location => GoRouteData.$location('/applications');

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
    '/applications/${Uri.encodeComponent(_self.applicationId)}',
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

mixin $CheckinRoute on GoRouteData {
  static CheckinRoute _fromState(GoRouterState state) => const CheckinRoute();

  @override
  String get location => GoRouteData.$location('/checkin');

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

mixin $SettlementRoute on GoRouteData {
  static SettlementRoute _fromState(GoRouterState state) =>
      const SettlementRoute();

  @override
  String get location => GoRouteData.$location('/settlement');

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

mixin $BankAccountRoute on GoRouteData {
  static BankAccountRoute _fromState(GoRouterState state) =>
      const BankAccountRoute();

  @override
  String get location => GoRouteData.$location('/settlement/bank-account');

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

mixin $SettlementDetailRoute on GoRouteData {
  static SettlementDetailRoute _fromState(GoRouterState state) =>
      SettlementDetailRoute(id: state.pathParameters['id']!);

  SettlementDetailRoute get _self => this as SettlementDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/settlement/${Uri.encodeComponent(_self.id)}');

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

mixin $MoreRoute on GoRouteData {
  static MoreRoute _fromState(GoRouterState state) => const MoreRoute();

  @override
  String get location => GoRouteData.$location('/more');

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

mixin $PartyListRoute on GoRouteData {
  static PartyListRoute _fromState(GoRouterState state) =>
      const PartyListRoute();

  @override
  String get location => GoRouteData.$location('/more/parties');

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
  String get location => GoRouteData.$location('/more/parties/create');

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
  String get location => GoRouteData.$location(
    '/more/parties/${Uri.encodeComponent(_self.partyId)}',
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

mixin $PartyEditRoute on GoRouteData {
  static PartyEditRoute _fromState(GoRouterState state) =>
      PartyEditRoute(partyId: state.pathParameters['partyId']!);

  PartyEditRoute get _self => this as PartyEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/more/parties/${Uri.encodeComponent(_self.partyId)}/edit',
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

mixin $PartyTicketEditRoute on GoRouteData {
  static PartyTicketEditRoute _fromState(GoRouterState state) =>
      PartyTicketEditRoute(
        partyId: state.pathParameters['partyId']!,
        ticketId: state.pathParameters['ticketId']!,
      );

  PartyTicketEditRoute get _self => this as PartyTicketEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/more/parties/${Uri.encodeComponent(_self.partyId)}/tickets/${Uri.encodeComponent(_self.ticketId)}/edit',
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
    '/more/parties/${Uri.encodeComponent(_self.partyId)}/events/create',
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
    '/more/parties/${Uri.encodeComponent(_self.partyId)}/events/${Uri.encodeComponent(_self.eventId)}',
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
    '/more/parties/${Uri.encodeComponent(_self.partyId)}/events/${Uri.encodeComponent(_self.eventId)}/tickets/create',
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
    '/more/parties/${Uri.encodeComponent(_self.partyId)}/events/${Uri.encodeComponent(_self.eventId)}/tickets/${Uri.encodeComponent(_self.ticketId)}/edit',
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

mixin $VerificationManageRoute on GoRouteData {
  static VerificationManageRoute _fromState(GoRouterState state) =>
      const VerificationManageRoute();

  @override
  String get location => GoRouteData.$location('/more/verifications/manage');

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

mixin $CreateVerificationRoute on GoRouteData {
  static CreateVerificationRoute _fromState(GoRouterState state) =>
      CreateVerificationRoute(
        partnerId: state.uri.queryParameters['partner-id'],
      );

  CreateVerificationRoute get _self => this as CreateVerificationRoute;

  @override
  String get location => GoRouteData.$location(
    '/more/verifications/create',
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

mixin $NotificationSettingsRoute on GoRouteData {
  static NotificationSettingsRoute _fromState(GoRouterState state) =>
      const NotificationSettingsRoute();

  @override
  String get location => GoRouteData.$location('/more/notification-settings');

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

mixin $DeletionReasonRoute on GoRouteData {
  static DeletionReasonRoute _fromState(GoRouterState state) =>
      const DeletionReasonRoute();

  @override
  String get location => GoRouteData.$location('/more/delete-account');

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

mixin $DeletionInfoRoute on GoRouteData {
  static DeletionInfoRoute _fromState(GoRouterState state) => DeletionInfoRoute(
    reasonCode: state.uri.queryParameters['reason-code'],
  );

  DeletionInfoRoute get _self => this as DeletionInfoRoute;

  @override
  String get location => GoRouteData.$location(
    '/more/delete-account/info',
    queryParams: {
      if (_self.reasonCode != null) 'reason-code': _self.reasonCode,
    },
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

mixin $DeletionVerifyRoute on GoRouteData {
  static DeletionVerifyRoute _fromState(GoRouterState state) =>
      DeletionVerifyRoute(
        reasonCode: state.uri.queryParameters['reason-code'],
      );

  DeletionVerifyRoute get _self => this as DeletionVerifyRoute;

  @override
  String get location => GoRouteData.$location(
    '/more/delete-account/verify',
    queryParams: {
      if (_self.reasonCode != null) 'reason-code': _self.reasonCode,
    },
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

mixin $DeletionCompleteRoute on GoRouteData {
  static DeletionCompleteRoute _fromState(GoRouterState state) =>
      const DeletionCompleteRoute();

  @override
  String get location => GoRouteData.$location('/more/delete-account/complete');

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

mixin $MemberListRoute on GoRouteData {
  static MemberListRoute _fromState(GoRouterState state) =>
      MemberListRoute(partnerId: state.pathParameters['partnerId']!);

  MemberListRoute get _self => this as MemberListRoute;

  @override
  String get location => GoRouteData.$location(
    '/more/partners/${Uri.encodeComponent(_self.partnerId)}/members',
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
    '/more/partners/${Uri.encodeComponent(_self.partnerId)}/members/${Uri.encodeComponent(_self.targetUserId)}/permission',
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
