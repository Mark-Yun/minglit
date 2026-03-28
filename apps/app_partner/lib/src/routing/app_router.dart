import 'package:app_partner/src/logic/onboarding_state_provider.dart';
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
  final onboardingRefresh = ValueNotifier<int>(0);

  ref
    ..listen(authStateChangesProvider, (_, next) {
      next.whenData((state) {
        authState.value = state;
      });
    })
    ..listen(onboardingStateProvider, (_, _) {
      onboardingRefresh.value++;
    });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: Listenable.merge([authState, onboardingRefresh]),
    redirect: (context, state) {
      // Access global auth state
      final isLoggedIn = ref.read(currentUserProvider) != null;
      final isLoggingIn = state.uri.path == '/login';
      final isApplyPage = state.uri.path.startsWith('/apply');
      final isWelcomePage = state.uri.path == '/welcome';

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

      // 3. Check onboarding state for authenticated users
      if (isLoggedIn) {
        final onboarding = ref.read(onboardingStateProvider);
        if (onboarding.hasValue) {
          final onboardingState = onboarding.value!;
          // Redirect new applicants to welcome page first
          if (!isApplyPage &&
              !isWelcomePage &&
              onboardingState == OnboardingState.needsApplication) {
            return '/welcome';
          }
          // Redirect users with draft in progress directly to apply wizard
          if (!isApplyPage &&
              !isWelcomePage &&
              onboardingState == OnboardingState.draftInProgress) {
            return '/apply';
          }
          // If on welcome page but no longer needsApplication, redirect away
          if (isWelcomePage &&
              onboardingState != OnboardingState.needsApplication) {
            return onboardingState == OnboardingState.draftInProgress
                ? '/apply'
                : '/';
          }
          // Redirect to status if pending/needs_correction
          if (!isApplyPage &&
              !isWelcomePage &&
              (onboardingState == OnboardingState.pendingReview ||
                  onboardingState == OnboardingState.needsCorrection)) {
            return '/apply/status';
          }
          // If on apply page but already has partner, redirect to home
          if (isApplyPage && onboardingState == OnboardingState.hasPartner) {
            return '/';
          }
        }
      }

      // No redirect needed
      return null;
    },
    routes: $appRoutes, // Generated routes from app_routes.dart
    observers: [MinglitNavigationObserver()],
  );
}
