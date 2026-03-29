import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppRoutes', () {
    late List<RouteBase> routes;

    setUp(() {
      routes = $appRoutes;
    });

    test('generates non-empty route list', () {
      expect(routes, isNotEmpty);
    });

    test('contains StatefulShellRoute for bottom navigation', () {
      final shellRoute = routes.whereType<StatefulShellRoute>().toList();
      expect(shellRoute, hasLength(1), reason: 'Exactly one shell route');
    });

    test('shell route has 5 branches', () {
      final shellRoute = routes.whereType<StatefulShellRoute>().first;
      // StatefulShellRoute exposes branches via route.branches
      expect(
        shellRoute.branches,
        hasLength(5),
        reason: '5 bottom nav tabs: home, applications, checkin, settlement, more',
      );
    });

    test('branch root paths match bottom nav tabs', () {
      final shellRoute = routes.whereType<StatefulShellRoute>().first;
      final rootPaths = shellRoute.branches
          .map((b) => (b.routes.first as GoRoute).path)
          .toList();

      expect(rootPaths, [
        '/',
        '/applications',
        '/checkin',
        '/settlement',
        '/more',
      ]);
    });

    test('top-level routes include login, apply, welcome, notifications', () {
      final goRoutes = routes.whereType<GoRoute>().toList();
      final paths = goRoutes.map((r) => r.path).toSet();

      expect(paths, containsAll([
        '/login',
        '/apply',
        '/apply/status',
        '/welcome',
        '/notifications',
      ]));
    });

    test('home branch has location guide sub-route', () {
      final shellRoute = routes.whereType<StatefulShellRoute>().first;
      final homeBranch = shellRoute.branches[0];
      final homeRoute = homeBranch.routes.first as GoRoute;

      final subPaths = homeRoute.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toSet();
      expect(subPaths, contains('guide/location'));
    });

    test('settlement branch has bank-account and detail sub-routes', () {
      final shellRoute = routes.whereType<StatefulShellRoute>().first;
      final settlementBranch = shellRoute.branches[3];
      final settlementRoute = settlementBranch.routes.first as GoRoute;

      final subPaths = settlementRoute.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toSet();
      expect(subPaths, containsAll(['bank-account', ':id']));
    });

    test('more branch has party management sub-routes', () {
      final shellRoute = routes.whereType<StatefulShellRoute>().first;
      final moreBranch = shellRoute.branches[4];
      final moreRoute = moreBranch.routes.first as GoRoute;

      final subPaths = moreRoute.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toSet();
      expect(subPaths, containsAll([
        'parties',
        'verifications/manage',
        'verifications/create',
        'notification-settings',
      ]));
    });
  });
}
