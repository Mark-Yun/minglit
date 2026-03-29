import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('appRoutes', () {
    test('contains PartnerShellRoute with 5 branches', () {
      final shellRoute = $appRoutes.whereType<StatefulShellRoute>().first;
      // 5 branches: Home, Application, Checkin, Settlement, More
      expect(shellRoute.branches.length, 5);
    });

    test('contains top-level non-shell routes', () {
      final goRoutes = $appRoutes.whereType<GoRoute>().toList();
      final paths = goRoutes.map((r) => r.path).toSet();

      expect(paths, contains('/login'));
      expect(paths, contains('/apply'));
      expect(paths, contains('/apply/status'));
      expect(paths, contains('/welcome'));
      expect(paths, contains('/notifications'));
      expect(paths, contains('/dev/user-switch'));
    });
  });

  group('Shell branch root paths', () {
    late StatefulShellRoute shellRoute;
    late List<String> branchRootPaths;

    setUp(() {
      shellRoute = $appRoutes.whereType<StatefulShellRoute>().first;
      branchRootPaths = shellRoute.branches
          .map((b) => (b.routes.first as GoRoute).path)
          .toList();
    });

    test('branch 0 is Home at /', () {
      expect(branchRootPaths[0], '/');
    });

    test('branch 1 is Applications at /applications', () {
      expect(branchRootPaths[1], '/applications');
    });

    test('branch 2 is Checkin at /checkin', () {
      expect(branchRootPaths[2], '/checkin');
    });

    test('branch 3 is Settlement at /settlement', () {
      expect(branchRootPaths[3], '/settlement');
    });

    test('branch 4 is More at /more', () {
      expect(branchRootPaths[4], '/more');
    });
  });

  group('Route location generation', () {
    test('HomeRoute location is /', () {
      expect(const HomeRoute().location, '/');
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

    test('ApplicationListRoute location is /applications', () {
      expect(const ApplicationListRoute().location, '/applications');
    });

    test('PartyListRoute location is /more/parties', () {
      expect(const PartyListRoute().location, '/more/parties');
    });
  });

  group('Branch sub-routes', () {
    late StatefulShellRoute shellRoute;

    setUp(() {
      shellRoute = $appRoutes.whereType<StatefulShellRoute>().first;
    });

    test('Home branch has location guide sub-route', () {
      final homeBranch = shellRoute.branches[0];
      final homeRoute = homeBranch.routes.first as GoRoute;
      final subPaths = homeRoute.routes.cast<GoRoute>().map((r) => r.path);
      expect(subPaths, contains('guide/location'));
    });

    test('Settlement branch has bank-account sub-route', () {
      final settlementBranch = shellRoute.branches[3];
      final settlementRoute = settlementBranch.routes.first as GoRoute;
      final subPaths = settlementRoute.routes.cast<GoRoute>().map(
        (r) => r.path,
      );
      expect(subPaths, contains('bank-account'));
    });

    test('More branch has parties sub-route', () {
      final moreBranch = shellRoute.branches[4];
      final moreRoute = moreBranch.routes.first as GoRoute;
      final subPaths = moreRoute.routes.cast<GoRoute>().map((r) => r.path);
      expect(subPaths, contains('parties'));
    });
  });
}
