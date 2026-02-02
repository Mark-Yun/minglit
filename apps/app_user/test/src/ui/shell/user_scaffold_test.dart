import 'package:app_user/src/ui/shell/user_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('UserScaffold', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return UserScaffold(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) =>
                        const Center(child: Text('Home Tab')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/explore',
                    builder: (context, state) =>
                        const Center(child: Text('Explore Tab')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/my',
                    builder: (context, state) =>
                        const Center(child: Text('My Tab')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });

    Widget createTestWidget() {
      return MaterialApp.router(
        theme: MinglitTheme.materialTheme,
        routerConfig: router,
      );
    }

    testWidgets('renders 3 navigation destinations', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('홈'), findsOneWidget);
      expect(find.text('탐색'), findsOneWidget);
      expect(find.text('마이'), findsOneWidget);
    });

    testWidgets('renders navigation icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Selected home icon (initial location is '/')
      expect(find.byIcon(Icons.home), findsOneWidget);
      // Unselected icons
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows home tab content initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Home Tab'), findsOneWidget);
    });

    testWidgets('switches to explore tab on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('탐색'));
      await tester.pumpAndSettle();

      expect(find.text('Explore Tab'), findsOneWidget);
    });

    testWidgets('switches to my page tab on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('마이'));
      await tester.pumpAndSettle();

      expect(find.text('My Tab'), findsOneWidget);
    });

    testWidgets('NavigationBar has transparent indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.indicatorColor, Colors.transparent);
    });
  });
}
