import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppRoutes — shell branches', () {
    // $partnerShellRoute is the generated StatefulShellRoute.
    // It contains 5 branches (Home, Application, Checkin, Settlement, More).
    late StatefulShellRoute shellRoute;

    setUp(() {
      shellRoute = $partnerShellRoute as StatefulShellRoute;
    });

    test('shell route has exactly 5 branches', () {
      expect(shellRoute.branches.length, 5);
    });

    test('branch 0 (Home) root path is /', () {
      final firstRoute = shellRoute.branches[0].routes.first as GoRoute;
      expect(firstRoute.path, '/');
    });

    test('branch 1 (Application) root path is /applications', () {
      final route = shellRoute.branches[1].routes.first as GoRoute;
      expect(route.path, '/applications');
    });

    test('branch 2 (Checkin) root path is /checkin', () {
      final route = shellRoute.branches[2].routes.first as GoRoute;
      expect(route.path, '/checkin');
    });

    test('branch 3 (Settlement) root path is /settlement', () {
      final route = shellRoute.branches[3].routes.first as GoRoute;
      expect(route.path, '/settlement');
    });

    test('branch 4 (More) root path is /more', () {
      final route = shellRoute.branches[4].routes.first as GoRoute;
      expect(route.path, '/more');
    });

    test('More branch has nested party/verification/member routes', () {
      final moreRoute = shellRoute.branches[4].routes.first as GoRoute;
      final subPaths = moreRoute.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(subPaths, containsAll([
        'parties',
        'verifications/manage',
        'verifications/create',
        'notification-settings',
      ]));
    });

    test('Settlement branch has bank-account sub-route', () {
      final settlementRoute = shellRoute.branches[3].routes.first as GoRoute;
      final subPaths = settlementRoute.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(subPaths, contains('bank-account'));
    });
  });

  group('AppRoutes — top-level routes', () {
    test('\$appRoutes contains expected top-level route count', () {
      // 6 top-level + 1 shell = 7
      expect($appRoutes.length, 7);
    });

    test('login route path is /login', () {
      final loginRoute = $appRoutes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == '/login');
      expect(loginRoute.path, '/login');
    });

    test('apply route path is /apply', () {
      final route = $appRoutes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == '/apply');
      expect(route.path, '/apply');
    });

    test('notifications route path is /notifications', () {
      final route = $appRoutes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == '/notifications');
      expect(route.path, '/notifications');
    });
  });

  group('AppRoutes — route data location', () {
    test('HomeRoute location is /', () {
      expect(const HomeRoute().location, '/');
    });

    test('ApplicationListRoute location is /applications', () {
      expect(const ApplicationListRoute().location, '/applications');
    });

    test('CheckinRoute location is /checkin', () {
      expect(const CheckinRoute().location, '/checkin');
    });

    test('SettlementRoute location is /settlement', () {
      expect(const SettlementRoute().location, '/settlement');
    });

    test('MoreRoute location is /more', () {
      expect(const MoreRoute().location, '/more');
    });

    test('LoginRoute location is /login', () {
      expect(const LoginRoute().location, '/login');
    });

    test('PartnerApplyRoute location is /apply', () {
      expect(const PartnerApplyRoute().location, '/apply');
    });

    test('PartyListRoute location is /more/parties', () {
      expect(const PartyListRoute().location, '/more/parties');
    });

    test('EventDetailRoute builds correct location', () {
      const route = EventDetailRoute(partyId: 'p1', eventId: 'e1');
      expect(route.location, '/more/parties/p1/events/e1');
    });

    test('MemberListRoute builds correct location', () {
      const route = MemberListRoute(partnerId: 'partner-1');
      expect(route.location, '/more/partners/partner-1/members');
    });
  });
}
