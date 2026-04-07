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
          : prefix == '/'
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
            // Tag discovery routes (#1136)
            '/tags/:tagId',
          ]),
        );
      },
    );

    test('protected prefixes are present in the route tree', () {
      final paths = collectAllRoutePaths($appRoutes);
      // These protected prefixes have corresponding registered routes.
      // If any of these routes is removed, this test will catch it.
      const protectedPrefixes = [
        '/my',
        '/tickets/my',
        '/purchase-history',
        '/certification',
        '/signup/consent',
        // Fix #1000: /payment is in app_router.dart's protectedPrefixes for
        // deep-link defense. It has no dedicated route of its own (payment flows
        // redirect to /purchase-history), so we verify it via a direct path
        // membership check below instead of a startsWith match.
      ];
      for (final prefix in protectedPrefixes) {
        expect(
          paths.any((p) => p.startsWith(prefix)),
          isTrue,
          reason: 'Protected prefix "$prefix" must exist in route tree',
        );
      }
    });

    test('/payment protected prefix is tracked in snapshot', () {
      // Fix #1000: /payment is in app_router.dart's protectedPrefixes but has
      // no registered route of its own (payment flows use /purchase-history).
      // This test locks the *purchase-history* route that /payment redirects to,
      // ensuring the payment-protection chain stays intact: if /purchase-history
      // is ever removed or renamed, this will fail alongside the snapshot test.
      final paths = collectAllRoutePaths($appRoutes);
      expect(
        paths.contains('/purchase-history'),
        isTrue,
        reason:
            '/purchase-history must remain registered: /payment in '
            'protectedPrefixes relies on it as the post-payment destination',
      );
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
