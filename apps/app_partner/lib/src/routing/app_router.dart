import 'package:app_partner/src/logic/current_partner_provider.dart';
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
  // Fix #1533: settlement 권한 변경 시 라우터를 강제 재평가한다.
  final settlementRefresh = ValueNotifier<int>(0);

  ref
    ..listen(authStateChangesProvider, (_, next) {
      next.whenData((state) {
        authState.value = state;
      });
    })
    ..listen(onboardingStateProvider, (_, _) {
      onboardingRefresh.value++;
    })
    ..listen(hasSettlementAccessProvider, (_, _) {
      settlementRefresh.value++;
    });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: Listenable.merge([
      authState,
      onboardingRefresh,
      settlementRefresh,
    ]),
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

      // 4. Fix #1533: /settlement 및 하위 경로는 SETTLEMENT_VIEW 권한 필수.
      //    로딩 중에는 리다이렉트하지 않는다 — refreshListenable이 provider 완료 시
      //    라우터를 재평가하므로 권한이 없는 사용자는 data(false)로 resolve된 뒤 차단된다.
      //    Note: path == '/settlement' || startsWith('/settlement/') 로 한정해야
      //    '/settlement-history' 같은 형제 경로를 잘못 차단하지 않는다.
      final path = state.uri.path;
      if (isLoggedIn &&
          (path == '/settlement' || path.startsWith('/settlement/'))) {
        final hasAccess = ref
            .read(hasSettlementAccessProvider)
            .maybeWhen(
              data: (v) => v,
              // Fix #1544: fail-closed — refreshListenable re-evals after resolve
              loading: () => false,
              orElse: () => false, // error: deny access (security-first)
            );
        if (!hasAccess) return '/';
      }

      // No redirect needed
      return null;
    },
    routes: $appRoutes, // Generated routes from app_routes.dart
    observers: [MinglitNavigationObserver()],
  );
}
