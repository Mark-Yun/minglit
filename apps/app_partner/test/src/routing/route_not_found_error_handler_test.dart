// Regression tests for #1699 and #1700 (app_partner):
// - #1699: unknown route crashed app (GoException → Android launcher)
// - #1700: unknown route exposed raw GoException message to user
//
// Tests use the PRODUCTION $appRoutes + RouteNotFoundPage so that:
// - Removing errorBuilder from app_router.dart breaks test 1 (crash).
// - Changing RouteNotFoundPage content breaks text assertions.
// SYNC REQUIREMENT: update assertions if RouteNotFoundPage content changes.

import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Test router uses production $appRoutes + RouteNotFoundPage.
// initialLocation is an unknown path so errorBuilder fires immediately,
// without rendering any real screen widget or requiring provider setup.
Widget _buildErrorPageApp() {
  final router = GoRouter(
    initialLocation: '/totally-unknown-path-xyz-doesnt-exist',
    routes: $appRoutes,
    errorBuilder: (context, state) => const RouteNotFoundPage(),
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets(
    '#1699 unknown route shows RouteNotFoundPage instead of crashing',
    (tester) async {
      await tester.pumpWidget(_buildErrorPageApp());
      await tester.pump();

      // Fix #1699: GoRouter errorBuilder catches unknown routes before they
      // propagate as GoException crashes.
      expect(find.byType(RouteNotFoundPage), findsOneWidget);
      expect(find.text('페이지를 찾을 수 없습니다.'), findsOneWidget);
    },
  );

  testWidgets(
    '#1700 unknown route shows user-friendly message, not raw GoException',
    (tester) async {
      await tester.pumpWidget(_buildErrorPageApp());
      await tester.pump();

      // Fix #1700: user sees friendly copy, not raw exception text.
      expect(find.text('페이지를 찾을 수 없습니다.'), findsOneWidget);
      expect(
        find.text('요청하신 페이지가 존재하지 않거나 이동되었습니다.'),
        findsOneWidget,
      );
      expect(find.textContaining('GoException'), findsNothing);
    },
  );

  testWidgets(
    'error page shows "홈으로" retry button',
    (tester) async {
      await tester.pumpWidget(_buildErrorPageApp());
      await tester.pump();

      expect(find.text('홈으로'), findsOneWidget);
    },
  );
}
