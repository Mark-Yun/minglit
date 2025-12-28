import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'app_router.g.dart';

// Global navigator key to allow context access.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// **Centralized Router Provider**
///
/// Configures [GoRouter] with:
/// 1. **Initial Location**: Default entry point (`/`).
/// 2. **Refresh Logic**: Listens to auth changes to auto-redirect.
/// 3. **Redirect Logic**: Enforces authentication policy.
/// 4. **Routes**: Uses Type-safe routes from app_routes.dart.
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
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authState,
    redirect: (context, state) {
      // Access global auth state
      final isLoggedIn = ref.read(currentUserProvider) != null;
      final isLoggingIn = state.uri.path == '/login';

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
  );
}
