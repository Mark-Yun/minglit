import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'app_router.g.dart';

/// Root navigator key shared with [BugReporterWrapper] for dialog display.
final rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(Ref ref) {
  // Listen to auth state changes to trigger router refresh.
  final authState = ValueNotifier<AuthState?>(null);

  ref.listen(authStateChangesProvider, (_, next) {
    next.whenData((state) {
      authState.value = state;
    });
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authState,
    redirect: (context, state) {
      // Access global auth state
      final isLoggedIn = ref.read(currentUserProvider) != null;
      final isLoggingIn = state.uri.path == '/login';

      // Allow dev pages without authentication
      if (state.uri.path.startsWith('/dev')) return null;

      // 1. If not logged in and not on login page -> Redirect to Login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // 2. If logged in and trying to access login page -> Redirect to Home
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      // No redirect needed
      return null;
    },
    routes: $appRoutes, // Generated routes from app_routes.dart
    observers: [MinglitNavigationObserver()],
  );
}
