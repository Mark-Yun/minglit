import 'dart:async';

import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Integration test용 TestApp 헬퍼.
/// 실제 Supabase/Firebase 없이 GoRouter 네비게이션을 테스트합니다.
Widget createTestApp({
  bool isLoggedIn = false,
  User? currentUser,
  List<dynamic> additionalOverrides = const [],
  String initialLocation = '/',
  List<Event>? events,
  List<Event>? feedEvents,
  /// When `isLoggedIn` is true, controls consent redirect behavior:
  /// - `null` (default): skip consent check entirely
  /// - `false`: user has NOT completed required consents → redirect to /signup/consent
  /// - `true`: user HAS completed required consents → no redirect
  bool? hasRequiredConsents,
}) {
  final testRouter = GoRouter(
    initialLocation: initialLocation,
    routes: $appRoutes,
    redirect: (context, state) {
      final path = state.uri.path;

      // /explore → / (backward compat)
      if (path.startsWith('/explore')) return '/';

      // /dev → bypass auth
      if (path.startsWith('/dev')) return null;

      final isLoggingIn = path == '/login';

      // Logged in + trying to access /login → redirect to `from` or home
      if (isLoggedIn && isLoggingIn) {
        final from = state.uri.queryParameters['from'];
        if (from != null &&
            from.startsWith('/') &&
            !from.startsWith('//') &&
            !from.startsWith('/login')) {
          return from;
        }
        return '/';
      }

      // Protected routes
      const protectedPrefixes = [
        '/my',
        '/tickets/my',
        '/payment',
        '/purchase-history',
        '/certification',
      ];
      final isProtected =
          protectedPrefixes.any(path.startsWith) || path.endsWith('/apply');

      // Not logged in + protected route → /login?from={path}
      if (!isLoggedIn && isProtected) {
        return Uri(
          path: '/login',
          queryParameters: {'from': path},
        ).toString();
      }

      // Fix #883: Consent redirect — mirrors app_router.dart production logic
      if (isLoggedIn && hasRequiredConsents != null) {
        if (path != '/signup/consent' && !hasRequiredConsents) {
          return '/signup/consent';
        }
        if (path == '/signup/consent' && hasRequiredConsents) {
          return '/';
        }
      }

      return null;
    },
  );

  return ProviderScope(
    overrides: [
      // Inject test router with isLoggedIn-based redirect (no Supabase needed)
      goRouterProvider.overrideWithValue(testRouter),
      // Auth providers
      currentUserProvider.overrideWith((_) => currentUser),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      authControllerProvider.overrideWith(_FakeAuthController.new),
      // Notification (prevent FCM platform channel errors)
      notificationInitializerProvider.overrideWith((_) {}),
      // Event/explore providers (prevent API calls)
      recommendationEventsProvider.overrideWith(
        (_) async => events ?? <Event>[],
      ),
      eventFeedProvider.overrideWith(
        (ref, arg) async => feedEvents ?? <Event>[],
      ),
      activeFiltersProvider.overrideWith(_NoFiltersNotifier.new),
      ...additionalOverrides.cast(),
    ],
    child: MaterialApp.router(
      theme: MinglitTheme.materialTheme,
      routerConfig: testRouter,
    ),
  );
}

/// Fake AuthController — returns immediately without calling Supabase
class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}

/// No-op ActiveFilters — disables location/eligibility filters in tests
class _NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}

/// Sets Korean locale for the test environment
void setKoreanLocale(WidgetTester tester) {
  tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
  tester.binding.platformDispatcher.localesTestValue = const [Locale('ko')];
}
