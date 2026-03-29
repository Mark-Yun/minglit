import 'package:app_partner/src/ui/shell/partner_scaffold.dart';
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
  late MockStatefulNavigationShell mockShell;

  setUp(() {
    mockShell = MockStatefulNavigationShell();
    when(() => mockShell.currentIndex).thenReturn(0);
  });

  /// Wraps [PartnerScaffold] in a [MaterialApp] with a [GoRouter] that
  /// exposes [GoRouterState] at the given [location].
  Widget buildSubject({
    String location = '/',
    int currentIndex = 0,
  }) {
    when(() => mockShell.currentIndex).thenReturn(currentIndex);

    final router = GoRouter(
      initialLocation: location,
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              PartnerScaffold(navigationShell: mockShell),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const SizedBox()),
            GoRoute(
              path: '/applications',
              builder: (_, _) => const SizedBox(),
            ),
            GoRoute(path: '/checkin', builder: (_, _) => const SizedBox()),
            GoRoute(path: '/settlement', builder: (_, _) => const SizedBox()),
            GoRoute(path: '/more', builder: (_, _) => const SizedBox()),
            GoRoute(
              path: '/more/parties',
              builder: (_, _) => const SizedBox(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('PartnerScaffold — bottom navigation bar', () {
    testWidgets('renders 5 NavigationDestination items', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('displays correct tab labels', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('홈'), findsOneWidget);
      expect(find.text('신청관리'), findsOneWidget);
      expect(find.text('체크인'), findsOneWidget);
      expect(find.text('정산'), findsOneWidget);
      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets('tabs are in correct order', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final labels = tester
          .widgetList<NavigationDestination>(
            find.byType(NavigationDestination),
          )
          .map((d) => d.label)
          .toList();

      expect(labels, ['홈', '신청관리', '체크인', '정산', '더보기']);
    });

    testWidgets('selectedIndex matches currentIndex from shell', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(currentIndex: 2));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });

    testWidgets('tapping a tab calls goBranch on the shell', (tester) async {
      when(
        () => mockShell.goBranch(
          any(),
          initialLocation: any(named: 'initialLocation'),
        ),
      ).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap the 정산 tab (index 3)
      await tester.tap(find.text('정산'));
      await tester.pumpAndSettle();

      verify(
        () => mockShell.goBranch(3),
      ).called(1);
    });

    testWidgets('tapping same tab resets to initial location', (tester) async {
      when(
        () => mockShell.goBranch(
          any(),
          initialLocation: any(named: 'initialLocation'),
        ),
      ).thenReturn(null);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap the 홈 tab while already on index 0
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();

      verify(
        () => mockShell.goBranch(0, initialLocation: true),
      ).called(1);
    });
  });

  group('PartnerScaffold — bottom nav visibility', () {
    testWidgets('bottom nav is visible on root path /', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('bottom nav is hidden on sub-route /more/parties', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(location: '/more/parties'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
