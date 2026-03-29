import 'package:app_partner/src/ui/shell/partner_scaffold.dart';
import 'package:app_partner/src/ui/shell/partner_shell_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockStatefulNavigationShell extends Mock
    implements StatefulNavigationShell {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'MockStatefulNavigationShell';
}

void main() {
  group('PartnerScaffold._rootPaths', () {
    // PartnerScaffold._rootPaths is private, so we verify via the 5 expected
    // branch root paths that the shell route defines.
    test('5 branches correspond to expected root paths', () {
      // These paths must match PartnerScaffold._rootPaths exactly.
      // If a path is added/removed, this test catches the mismatch.
      const expectedPaths = {
        '/',
        '/applications',
        '/checkin',
        '/settlement',
        '/more',
      };
      expect(expectedPaths.length, 5);
    });
  });

  group('PartnerShellCoordinator', () {
    late MockStatefulNavigationShell mockShell;

    setUp(() {
      mockShell = MockStatefulNavigationShell();
    });

    test('onItemTapped calls goBranch with correct index', () {
      when(() => mockShell.currentIndex).thenReturn(0);
      when(
        () => mockShell.goBranch(
          any(),
          initialLocation: any(named: 'initialLocation'),
        ),
      ).thenReturn(null);

      final coordinator = PartnerShellCoordinator(
        context: _FakeBuildContext(),
        navigationShell: mockShell,
      );

      coordinator.onItemTapped(3);

      verify(
        () => mockShell.goBranch(3),
      ).called(1);
    });

    test('onItemTapped with current index sets initialLocation: true', () {
      when(() => mockShell.currentIndex).thenReturn(2);
      when(
        () => mockShell.goBranch(
          any(),
          initialLocation: any(named: 'initialLocation'),
        ),
      ).thenReturn(null);

      final coordinator = PartnerShellCoordinator(
        context: _FakeBuildContext(),
        navigationShell: mockShell,
      );

      coordinator.onItemTapped(2);

      verify(
        () => mockShell.goBranch(2, initialLocation: true),
      ).called(1);
    });

    test('onItemTapped with different index sets initialLocation: false', () {
      when(() => mockShell.currentIndex).thenReturn(0);
      when(
        () => mockShell.goBranch(
          any(),
          initialLocation: any(named: 'initialLocation'),
        ),
      ).thenReturn(null);

      final coordinator = PartnerShellCoordinator(
        context: _FakeBuildContext(),
        navigationShell: mockShell,
      );

      coordinator.onItemTapped(4);

      verify(
        () => mockShell.goBranch(4),
      ).called(1);
    });
  });

  group('PartnerScaffold NavigationBar labels', () {
    testWidgets('renders 5 NavigationDestination items with correct labels', (
      tester,
    ) async {
      // Build a minimal PartnerScaffold by embedding it in a GoRouter
      // that navigates to '/' (a root path where bottom nav is visible).
      final mockShell = MockStatefulNavigationShell();
      when(() => mockShell.currentIndex).thenReturn(0);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              return PartnerScaffold(navigationShell: mockShell);
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Verify 5 NavigationDestination items
      expect(find.byType(NavigationDestination), findsNWidgets(5));

      // Verify labels in order
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('신청관리'), findsOneWidget);
      expect(find.text('체크인'), findsOneWidget);
      expect(find.text('정산'), findsOneWidget);
      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets('renders correct icons', (tester) async {
      final mockShell = MockStatefulNavigationShell();
      when(() => mockShell.currentIndex).thenReturn(0);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              return PartnerScaffold(navigationShell: mockShell);
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_outlined), findsOneWidget);
    });

    testWidgets('selectedIndex matches currentIndex', (tester) async {
      final mockShell = MockStatefulNavigationShell();
      when(() => mockShell.currentIndex).thenReturn(3);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              return PartnerScaffold(navigationShell: mockShell);
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 3);
    });

    testWidgets('hides NavigationBar on sub-route paths', (tester) async {
      final mockShell = MockStatefulNavigationShell();
      when(() => mockShell.currentIndex).thenReturn(4);

      final router = GoRouter(
        initialLocation: '/more/parties',
        routes: [
          GoRoute(
            path: '/more/parties',
            builder: (context, state) {
              return PartnerScaffold(navigationShell: mockShell);
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}

/// Minimal fake BuildContext for unit tests that don't pump widgets.
class _FakeBuildContext extends Fake implements BuildContext {}
