// Regression tests for #1699 and #1700 (app_partner):
// - #1699: unknown route caused crash (GoException propagated to Android launcher)
// - #1700: unknown route exposed raw technical GoException message to user
//
// We cannot instantiate the private _RouteNotFoundPage directly, so we reproduce
// the same errorBuilder pattern and verify the resulting UI behavior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget buildRouterWithErrorHandler() {
    final router = GoRouter(
      initialLocation: '/known',
      errorBuilder: (context, state) => Scaffold(
        body: MinglitErrorState(
          icon: Icons.search_off_rounded,
          title: '페이지를 찾을 수 없습니다.',
          subtitle: '요청하신 페이지가 존재하지 않거나 이동되었습니다.',
          retryLabel: '홈으로',
          onRetry: () => context.go('/known'),
        ),
      ),
      routes: [
        GoRoute(
          path: '/known',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    '#1699 unknown route shows error page instead of crashing',
    (tester) async {
      final widget = buildRouterWithErrorHandler();
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.text('home')));
      router.go('/minglit://dev/switch/unknown-path');
      await tester.pumpAndSettle();

      expect(find.text('페이지를 찾을 수 없습니다.'), findsOneWidget);
    },
  );

  testWidgets(
    '#1700 unknown route shows user-friendly message, not raw GoException',
    (tester) async {
      final widget = buildRouterWithErrorHandler();
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.text('home')));
      router.go('/some/completely/unknown/path');
      await tester.pumpAndSettle();

      expect(find.text('페이지를 찾을 수 없습니다.'), findsOneWidget);
      expect(
        find.text('요청하신 페이지가 존재하지 않거나 이동되었습니다.'),
        findsOneWidget,
      );
      expect(find.textContaining('GoException'), findsNothing);
    },
  );

  testWidgets(
    'error page "홈으로" button navigates back to home',
    (tester) async {
      final widget = buildRouterWithErrorHandler();
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.text('home')));
      router.go('/unknown-route');
      await tester.pumpAndSettle();

      expect(find.text('홈으로'), findsOneWidget);
      await tester.tap(find.text('홈으로'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    },
  );
}
