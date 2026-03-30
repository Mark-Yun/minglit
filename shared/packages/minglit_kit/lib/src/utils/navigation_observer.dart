import 'package:flutter/widgets.dart';
import 'package:minglit_kit/src/utils/log.dart';

/// **Minglit Navigation Observer**
///
/// Logs all navigation events (Push, Pop, Replace, Remove) to the console
/// using [Log.i] to track user actions/flows.
class MinglitNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation('POP', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logNavigation('REPLACE', newRoute, oldRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _logNavigation('REMOVE', route, previousRoute);
  }

  void _logNavigation(
    String action,
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    final routeName = route.settings.name ?? 'Unknown Route';
    final routeArgs = route.settings.arguments;
    final prevName = previousRoute?.settings.name;

    final prevMsg = prevName != null ? ' (from $prevName)' : '';
    final argsMsg = routeArgs != null ? ' | args: $routeArgs' : '';

    Log.i('🧭 [Nav] $action: $routeName$prevMsg$argsMsg');
  }
}
