import 'package:app_user/src/ui/shell/nav_visibility_provider.dart';
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
      return ProviderScope(
        overrides: [
          // Make nav bar visible so tap tests work
          navVisibilityProvider.overrideWith(_AlwaysVisibleNavNotifier.new),
        ],
        child: MaterialApp.router(
          theme: MinglitTheme.materialTheme,
          routerConfig: router,
        ),
      );
    }

    testWidgets('renders 2 navigation destinations', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('홈'), findsOneWidget);
      expect(find.text('마이'), findsOneWidget);
    });

    testWidgets('renders navigation icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Selected home icon (initial location is '/')
      expect(find.byIcon(Icons.home), findsOneWidget);
      // Unselected my page icon
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows home tab content initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Home Tab'), findsOneWidget);
    });

    testWidgets('switches to my page tab on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('마이'));
      await tester.pumpAndSettle();

      expect(find.text('My Tab'), findsOneWidget);
    });

    testWidgets('NavigationBar renders with expected properties', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.elevation, 0);
      expect(navBar.height, 64);
      expect(navBar.backgroundColor, MinglitColors.transparent);
    });

    testWidgets('renders two NavigationDestination widgets', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDestination), findsNWidgets(2));
    });
  });
}

class _AlwaysVisibleNavNotifier extends NavVisibility {
  @override
  bool build() => true;
}
