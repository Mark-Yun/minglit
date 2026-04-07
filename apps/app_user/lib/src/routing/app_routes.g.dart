// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $devUserSwitchRoute,
  $loginRoute,
  $signupConsentRoute,
  $authCallbackRoute,
  $eventDetailRoute,
  $partnerDetailRoute,
  $partnerEventsRoute,
  $certificationRoute,
  $eventApplicationRoute,
  $myTicketsRoute,
  $ticketQRRoute,
  $purchaseHistoryRoute,
  $notificationCenterRoute,
  $notificationSettingsRoute,
  $homeRoute,
  $searchRoute,
  $myPageRoute,
  $privacyRoute,
  $deletionReasonRoute,
  $deletionInfoRoute,
  $deletionVerifyRoute,
  $deletionCompleteRoute,
  $blockedPartnersRoute,
  $tagEventListRoute,
];

RouteBase get $devUserSwitchRoute => GoRouteData.$route(
  path: '/dev/switch',
  factory: $DevUserSwitchRoute._fromState,
);

mixin $DevUserSwitchRoute on GoRouteData {
  static DevUserSwitchRoute _fromState(GoRouterState state) =>
      const DevUserSwitchRoute();

  @override
  String get location => GoRouteData.$location('/dev/switch');

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
  static LoginRoute _fromState(GoRouterState state) =>
      LoginRoute(from: state.uri.queryParameters['from']);

  LoginRoute get _self => this as LoginRoute;

  @override
  String get location => GoRouteData.$location(
    '/login',
    queryParams: {if (_self.from != null) 'from': _self.from},
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

RouteBase get $signupConsentRoute => GoRouteData.$route(
  path: '/signup/consent',
  factory: $SignupConsentRoute._fromState,
);

mixin $SignupConsentRoute on GoRouteData {
  static SignupConsentRoute _fromState(GoRouterState state) =>
      SignupConsentRoute(from: state.uri.queryParameters['from']);

  SignupConsentRoute get _self => this as SignupConsentRoute;

  @override
  String get location => GoRouteData.$location(
    '/signup/consent',
    queryParams: {if (_self.from != null) 'from': _self.from},
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

RouteBase get $authCallbackRoute => GoRouteData.$route(
  path: '/auth/callback',
  factory: $AuthCallbackRoute._fromState,
);

mixin $AuthCallbackRoute on GoRouteData {
  static AuthCallbackRoute _fromState(GoRouterState state) =>
      const AuthCallbackRoute();

  @override
  String get location => GoRouteData.$location('/auth/callback');

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

RouteBase get $eventDetailRoute => GoRouteData.$route(
  path: '/events/:eventId',
  factory: $EventDetailRoute._fromState,
);

mixin $EventDetailRoute on GoRouteData {
  static EventDetailRoute _fromState(GoRouterState state) =>
      EventDetailRoute(eventId: state.pathParameters['eventId']!);

  EventDetailRoute get _self => this as EventDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/events/${Uri.encodeComponent(_self.eventId)}');

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

RouteBase get $partnerDetailRoute => GoRouteData.$route(
  path: '/partners/:partnerId',
  factory: $PartnerDetailRoute._fromState,
);

mixin $PartnerDetailRoute on GoRouteData {
  static PartnerDetailRoute _fromState(GoRouterState state) =>
      PartnerDetailRoute(partnerId: state.pathParameters['partnerId']!);

  PartnerDetailRoute get _self => this as PartnerDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/partners/${Uri.encodeComponent(_self.partnerId)}',
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

RouteBase get $partnerEventsRoute => GoRouteData.$route(
  path: '/partners/:partnerId/events',
  factory: $PartnerEventsRoute._fromState,
);

mixin $PartnerEventsRoute on GoRouteData {
  static PartnerEventsRoute _fromState(GoRouterState state) =>
      PartnerEventsRoute(
        partnerId: state.pathParameters['partnerId']!,
        partnerName: state.uri.queryParameters['partner-name']!,
      );

  PartnerEventsRoute get _self => this as PartnerEventsRoute;

  @override
  String get location => GoRouteData.$location(
    '/partners/${Uri.encodeComponent(_self.partnerId)}/events',
    queryParams: {'partner-name': _self.partnerName},
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

RouteBase get $certificationRoute => GoRouteData.$route(
  path: '/certification',
  factory: $CertificationRoute._fromState,
);

mixin $CertificationRoute on GoRouteData {
  static CertificationRoute _fromState(GoRouterState state) =>
      const CertificationRoute();

  @override
  String get location => GoRouteData.$location('/certification');

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

RouteBase get $eventApplicationRoute => GoRouteData.$route(
  path: '/events/:eventId/apply',
  factory: $EventApplicationRoute._fromState,
);

mixin $EventApplicationRoute on GoRouteData {
  static EventApplicationRoute _fromState(GoRouterState state) =>
      EventApplicationRoute(
        eventId: state.pathParameters['eventId']!,
        ticketId: state.uri.queryParameters['ticket-id'],
      );

  EventApplicationRoute get _self => this as EventApplicationRoute;

  @override
  String get location => GoRouteData.$location(
    '/events/${Uri.encodeComponent(_self.eventId)}/apply',
    queryParams: {if (_self.ticketId != null) 'ticket-id': _self.ticketId},
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

RouteBase get $myTicketsRoute => GoRouteData.$route(
  path: '/tickets/my',
  factory: $MyTicketsRoute._fromState,
);

mixin $MyTicketsRoute on GoRouteData {
  static MyTicketsRoute _fromState(GoRouterState state) =>
      const MyTicketsRoute();

  @override
  String get location => GoRouteData.$location('/tickets/my');

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

RouteBase get $ticketQRRoute => GoRouteData.$route(
  path: '/tickets/:ticketId/qr',
  factory: $TicketQRRoute._fromState,
);

mixin $TicketQRRoute on GoRouteData {
  static TicketQRRoute _fromState(GoRouterState state) =>
      TicketQRRoute(ticketId: state.pathParameters['ticketId']!);

  TicketQRRoute get _self => this as TicketQRRoute;

  @override
  String get location => GoRouteData.$location(
    '/tickets/${Uri.encodeComponent(_self.ticketId)}/qr',
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

RouteBase get $purchaseHistoryRoute => GoRouteData.$route(
  path: '/purchase-history',
  factory: $PurchaseHistoryRoute._fromState,
);

mixin $PurchaseHistoryRoute on GoRouteData {
  static PurchaseHistoryRoute _fromState(GoRouterState state) =>
      const PurchaseHistoryRoute();

  @override
  String get location => GoRouteData.$location('/purchase-history');

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

RouteBase get $notificationSettingsRoute => GoRouteData.$route(
  path: '/my/notification-settings',
  factory: $NotificationSettingsRoute._fromState,
);

mixin $NotificationSettingsRoute on GoRouteData {
  static NotificationSettingsRoute _fromState(GoRouterState state) =>
      const NotificationSettingsRoute();

  @override
  String get location => GoRouteData.$location('/my/notification-settings');

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

RouteBase get $homeRoute => GoRouteData.$route(
  path: '/',
  factory: $HomeRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'curation',
      factory: $EventCurationRoute._fromState,
    ),
  ],
);

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

mixin $EventCurationRoute on GoRouteData {
  static EventCurationRoute _fromState(GoRouterState state) =>
      EventCurationRoute(
        type:
            _$convertMapValue(
              'type',
              state.uri.queryParameters,
              _$EventFeedTypeEnumMap._$fromName,
            ) ??
            EventFeedType.newArrivals,
      );

  EventCurationRoute get _self => this as EventCurationRoute;

  @override
  String get location => GoRouteData.$location(
    '/curation',
    queryParams: {
      if (_self.type != EventFeedType.newArrivals)
        'type': _$EventFeedTypeEnumMap[_self.type],
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

const _$EventFeedTypeEnumMap = {
  EventFeedType.nearest: 'nearest',
  EventFeedType.newArrivals: 'new-arrivals',
  EventFeedType.closingSoon: 'closing-soon',
  EventFeedType.earlyBird: 'early-bird',
  EventFeedType.aiRecommended: 'ai-recommended',
};

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

extension<T extends Enum> on Map<T, String> {
  T? _$fromName(String? value) =>
      entries.where((element) => element.value == value).firstOrNull?.key;
}

RouteBase get $searchRoute =>
    GoRouteData.$route(path: '/search', factory: $SearchRoute._fromState);

mixin $SearchRoute on GoRouteData {
  static SearchRoute _fromState(GoRouterState state) => const SearchRoute();

  @override
  String get location => GoRouteData.$location('/search');

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

RouteBase get $myPageRoute =>
    GoRouteData.$route(path: '/my', factory: $MyPageRoute._fromState);

mixin $MyPageRoute on GoRouteData {
  static MyPageRoute _fromState(GoRouterState state) => const MyPageRoute();

  @override
  String get location => GoRouteData.$location('/my');

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

RouteBase get $privacyRoute =>
    GoRouteData.$route(path: '/my/privacy', factory: $PrivacyRoute._fromState);

mixin $PrivacyRoute on GoRouteData {
  static PrivacyRoute _fromState(GoRouterState state) => const PrivacyRoute();

  @override
  String get location => GoRouteData.$location('/my/privacy');

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

RouteBase get $deletionReasonRoute => GoRouteData.$route(
  path: '/my/privacy/delete/reason',
  factory: $DeletionReasonRoute._fromState,
);

mixin $DeletionReasonRoute on GoRouteData {
  static DeletionReasonRoute _fromState(GoRouterState state) =>
      const DeletionReasonRoute();

  @override
  String get location => GoRouteData.$location('/my/privacy/delete/reason');

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

RouteBase get $deletionInfoRoute => GoRouteData.$route(
  path: '/my/privacy/delete/info',
  factory: $DeletionInfoRoute._fromState,
);

mixin $DeletionInfoRoute on GoRouteData {
  static DeletionInfoRoute _fromState(GoRouterState state) => DeletionInfoRoute(
    reasonCode: state.uri.queryParameters['reason-code'],
    reasonText: state.uri.queryParameters['reason-text'],
  );

  DeletionInfoRoute get _self => this as DeletionInfoRoute;

  @override
  String get location => GoRouteData.$location(
    '/my/privacy/delete/info',
    queryParams: {
      if (_self.reasonCode != null) 'reason-code': _self.reasonCode,
      if (_self.reasonText != null) 'reason-text': _self.reasonText,
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

RouteBase get $deletionVerifyRoute => GoRouteData.$route(
  path: '/my/privacy/delete/verify',
  factory: $DeletionVerifyRoute._fromState,
);

mixin $DeletionVerifyRoute on GoRouteData {
  static DeletionVerifyRoute _fromState(GoRouterState state) =>
      DeletionVerifyRoute(
        reasonCode: state.uri.queryParameters['reason-code'],
        reasonText: state.uri.queryParameters['reason-text'],
      );

  DeletionVerifyRoute get _self => this as DeletionVerifyRoute;

  @override
  String get location => GoRouteData.$location(
    '/my/privacy/delete/verify',
    queryParams: {
      if (_self.reasonCode != null) 'reason-code': _self.reasonCode,
      if (_self.reasonText != null) 'reason-text': _self.reasonText,
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

RouteBase get $deletionCompleteRoute => GoRouteData.$route(
  path: '/my/privacy/delete/complete',
  factory: $DeletionCompleteRoute._fromState,
);

mixin $DeletionCompleteRoute on GoRouteData {
  static DeletionCompleteRoute _fromState(GoRouterState state) =>
      const DeletionCompleteRoute();

  @override
  String get location => GoRouteData.$location('/my/privacy/delete/complete');

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

RouteBase get $blockedPartnersRoute => GoRouteData.$route(
  path: '/my/blocked-partners',
  factory: $BlockedPartnersRoute._fromState,
);

mixin $BlockedPartnersRoute on GoRouteData {
  static BlockedPartnersRoute _fromState(GoRouterState state) =>
      const BlockedPartnersRoute();

  @override
  String get location => GoRouteData.$location('/my/blocked-partners');

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

RouteBase get $tagEventListRoute => GoRouteData.$route(
  path: '/tags/:tagId',
  factory: $TagEventListRoute._fromState,
);

mixin $TagEventListRoute on GoRouteData {
  static TagEventListRoute _fromState(GoRouterState state) =>
      TagEventListRoute(
        tagId: state.pathParameters['tagId']!,
        tagName: state.uri.queryParameters['tagName'] ?? '',
      );

  TagEventListRoute get _self => this as TagEventListRoute;

  @override
  String get location => GoRouteData.$location(
    '/tags/${Uri.encodeComponent(_self.tagId)}',
    queryParams: {
      'tagName': _self.tagName,
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
