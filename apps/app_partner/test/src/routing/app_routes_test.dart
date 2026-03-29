import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppRoutes', () {
    test(r'$appRoutes contains 7 top-level routes', () {
      // 6 top-level + 1 shell route
      expect($appRoutes.length, 7);
    });

    group('top-level routes', () {
      test('DevUserSwitchRoute has path /dev/user-switch', () {
        final route = $devUserSwitchRoute as GoRoute;
        expect(route.path, '/dev/user-switch');
      });

      test('LoginRoute has path /login', () {
        final route = $loginRoute as GoRoute;
        expect(route.path, '/login');
      });

      test('PartnerApplyRoute has path /apply', () {
        final route = $partnerApplyRoute as GoRoute;
        expect(route.path, '/apply');
      });

      test('PartnerApplyStatusRoute has path /apply/status', () {
        final route = $partnerApplyStatusRoute as GoRoute;
        expect(route.path, '/apply/status');
      });

      test('PartnerWelcomeRoute has path /welcome', () {
        final route = $partnerWelcomeRoute as GoRoute;
        expect(route.path, '/welcome');
      });

      test('NotificationCenterRoute has path /notifications', () {
        final route = $notificationCenterRoute as GoRoute;
        expect(route.path, '/notifications');
      });
    });

    group('shell route branches', () {
      late StatefulShellRoute shellRoute;

      setUp(() {
        shellRoute = $partnerShellRoute as StatefulShellRoute;
      });

      test('shell route has 5 branches', () {
        expect(shellRoute.branches.length, 5);
      });

      test('branch 0 (Home) root path is /', () {
        final homeRoute = shellRoute.branches[0].routes.first as GoRoute;
        expect(homeRoute.path, '/');
      });

      test('branch 1 (Applications) root path is /applications', () {
        final route = shellRoute.branches[1].routes.first as GoRoute;
        expect(route.path, '/applications');
      });

      test('branch 2 (Check-in) root path is /checkin', () {
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

      test('Home branch has sub-route guide/location', () {
        final homeRoute = shellRoute.branches[0].routes.first as GoRoute;
        expect(homeRoute.routes.length, 1);
        expect((homeRoute.routes.first as GoRoute).path, 'guide/location');
      });

      test('Applications branch has sub-route :applicationId', () {
        final route = shellRoute.branches[1].routes.first as GoRoute;
        expect(route.routes.length, 1);
        expect((route.routes.first as GoRoute).path, ':applicationId');
      });

      test('Settlement branch has sub-routes bank-account and :id', () {
        final route = shellRoute.branches[3].routes.first as GoRoute;
        final subPaths = route.routes.map((r) => (r as GoRoute).path).toList();
        expect(subPaths, containsAll(['bank-account', ':id']));
      });

      test('More branch contains party management routes', () {
        final moreRoute = shellRoute.branches[4].routes.first as GoRoute;
        final subPaths = moreRoute.routes
            .map((r) => (r as GoRoute).path)
            .toList();
        expect(subPaths, contains('parties'));
      });
    });
  });
}
