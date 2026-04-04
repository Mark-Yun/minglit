// Tests for #1000: Route path snapshot — new route additions auto-detected.
// Update the expected list below when intentionally adding/removing routes.

import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Recursively collects all full route paths from a GoRouter route tree.
List<String> collectAllRoutePaths(
  List<RouteBase> routes, [
  String prefix = '',
]) {
  final paths = <String>[];
  for (final route in routes) {
    if (route is GoRoute) {
      final fullPath = route.path.startsWith('/')
          ? route.path
          : prefix.isEmpty
          ? '/${route.path}'
          : '$prefix/${route.path}';
      paths.add(fullPath);
      paths.addAll(collectAllRoutePaths(route.routes, fullPath));
    } else if (route is ShellRoute) {
      paths.addAll(collectAllRoutePaths(route.routes, prefix));
    } else if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        paths.addAll(collectAllRoutePaths(branch.routes, prefix));
      }
    }
  }
  return paths;
}

void main() {
  group('app_user route path snapshot', () {
    // Fix #1000: snapshot guards against accidental route additions/removals.
    // Update this list when routes are intentionally changed.
    test(
      'all route paths match snapshot — update when adding/removing routes',
      () {
        final paths = collectAllRoutePaths($appRoutes);

        expect(
          paths,
          unorderedEquals(<String>[
            // Top-level routes (outside shell)
            '/dev/switch',
            '/login',
            '/signup/consent',
            '/auth/callback',
            '/events/:eventId',
            '/partners/:partnerId',
            '/partners/:partnerId/events',
            '/certification',
            '/events/:eventId/apply',
            '/tickets/my',
            '/tickets/:ticketId/qr',
            '/purchase-history',
            '/notifications',
            '/my/notification-settings',
            // Shell routes
            '/',
            '/curation',
            '/search',
            '/my',
            '/my/privacy',
            '/my/privacy/delete/reason',
            '/my/privacy/delete/info',
            '/my/privacy/delete/verify',
            '/my/privacy/delete/complete',
            '/my/blocked-partners',
          ]),
        );
      },
    );

    test('protected prefixes are present in the route tree', () {
      final paths = collectAllRoutePaths($appRoutes);
      const protectedPrefixes = [
        '/my',
        '/tickets/my',
        '/payment',
        '/purchase-history',
        '/certification',
        '/signup/consent',
      ];
      for (final prefix in protectedPrefixes) {
        expect(
          paths.any((p) => p.startsWith(prefix)),
          isTrue,
          reason: 'Protected prefix "$prefix" must exist in route tree',
        );
      }
    });

    test('/apply suffix route is registered', () {
      final paths = collectAllRoutePaths($appRoutes);
      expect(
        paths.any((p) => p.endsWith('/apply')),
        isTrue,
        reason: '/apply suffix route (/events/:id/apply) must be registered',
      );
    });
  });
}
