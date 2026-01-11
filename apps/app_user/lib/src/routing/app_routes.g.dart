// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $devRoute,
  $devUserSwitchRoute,
  $loginRoute,
  $homeRoute,
  $eventCurationRoute,
  $eventDetailRoute,
];

RouteBase get $devRoute =>
    GoRouteData.$route(path: '/dev', factory: $DevRoute._fromState);

mixin $DevRoute on GoRouteData {
  static DevRoute _fromState(GoRouterState state) => const DevRoute();

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

RouteBase get $eventCurationRoute => GoRouteData.$route(
  path: '/curation',
  factory: $EventCurationRoute._fromState,
);

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
