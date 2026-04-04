import 'dart:async';

import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_status_page.dart';
import 'package:app_partner/src/features/onboarding/partner_welcome_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

// ---------------------------------------------------------------------------
// Test app helper
// ---------------------------------------------------------------------------

/// Creates an integration test app for the partner app router redirect logic.
/// Mirrors the redirect logic from [app_partner/src/routing/app_router.dart]
/// without requiring Supabase or Firebase.
Widget _createPartnerTestApp({
  bool isLoggedIn = false,
  User? currentUser,
  AsyncValue<OnboardingState> onboardingState = const AsyncData(
    OnboardingState.hasPartner,
  ),
  String initialLocation = '/',
}) {
  final testRouter = GoRouter(
    initialLocation: initialLocation,
    routes: $appRoutes,
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggingIn = path == '/login';
      final isApplyPage = path.startsWith('/apply');
      final isWelcomePage = path == '/welcome';

      // Allow dev pages without authentication
      if (path.startsWith('/dev')) return null;

      // 1. Not logged in and not on login page → /login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // 2. Logged in and trying to access login page → /
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      // 3. Onboarding-state-based redirects for authenticated users
      if (isLoggedIn && onboardingState.hasValue) {
        final state_ = onboardingState.value!;

        if (!isApplyPage &&
            !isWelcomePage &&
            state_ == OnboardingState.needsApplication) {
          return '/welcome';
        }

        if (!isApplyPage &&
            !isWelcomePage &&
            state_ == OnboardingState.draftInProgress) {
          return '/apply';
        }

        if (isWelcomePage && state_ != OnboardingState.needsApplication) {
          return state_ == OnboardingState.draftInProgress ? '/apply' : '/';
        }

        if (!isApplyPage &&
            !isWelcomePage &&
            (state_ == OnboardingState.pendingReview ||
                state_ == OnboardingState.needsCorrection)) {
          return '/apply/status';
        }

        if (isApplyPage && state_ == OnboardingState.hasPartner) {
          return '/';
        }
      }

      return null;
    },
  );

  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((_) => currentUser),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      authControllerProvider.overrideWith(_FakeAuthController.new),
      notificationInitializerProvider.overrideWith((_) {}),
      onboardingStateProvider.overrideWith((_) async {
        if (onboardingState.hasValue) return onboardingState.value!;
        throw StateError('loading');
      }),
    ],
    child: MaterialApp.router(
      theme: MinglitTheme.materialTheme,
      routerConfig: testRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// Fake AuthController — returns immediately without calling Supabase.
class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Partner Redirect Flow', () {
    // Test 1: Not logged in → any non-/login route → PartnerLoginPage
    testWidgets('비로그인: / 접근 시 PartnerLoginPage로 리다이렉트', (tester) async {
      await tester.pumpWidget(
        _createPartnerTestApp(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerLoginPage), findsOneWidget);
      expect(find.byType(PartnerHomePage), findsNothing);
    });

    // Test 2: Not logged in → /login → stays on PartnerLoginPage (no redirect)
    testWidgets('비로그인: /login 접근 시 리다이렉트 없이 PartnerLoginPage 표시', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createPartnerTestApp(initialLocation: '/login'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerLoginPage), findsOneWidget);
    });

    // Test 3: Logged in + /login → redirected to home
    testWidgets('로그인 상태: /login 접근 시 홈(PartnerHomePage)으로 리다이렉트', (
      tester,
    ) async {
      final user = User(
        id: 'partner-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );
      await tester.pumpWidget(
        _createPartnerTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/login',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerHomePage), findsOneWidget);
      expect(find.byType(PartnerLoginPage), findsNothing);
    });

    // Test 4: needsApplication → redirected to /welcome
    testWidgets('needsApplication: / 접근 시 PartnerWelcomePage로 리다이렉트', (
      tester,
    ) async {
      final user = User(
        id: 'partner-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );
      await tester.pumpWidget(
        _createPartnerTestApp(
          isLoggedIn: true,
          currentUser: user,
          onboardingState: const AsyncData(OnboardingState.needsApplication),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerWelcomePage), findsOneWidget);
      expect(find.byType(PartnerHomePage), findsNothing);
    });

    // Test 5: draftInProgress → redirected to /apply
    testWidgets('draftInProgress: / 접근 시 PartnerApplyPage로 리다이렉트', (
      tester,
    ) async {
      final user = User(
        id: 'partner-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );
      await tester.pumpWidget(
        _createPartnerTestApp(
          isLoggedIn: true,
          currentUser: user,
          onboardingState: const AsyncData(OnboardingState.draftInProgress),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerApplyPage), findsOneWidget);
      expect(find.byType(PartnerHomePage), findsNothing);
    });

    // Test 6: pendingReview → redirected to /apply/status
    testWidgets('pendingReview: / 접근 시 PartnerApplyStatusPage로 리다이렉트', (
      tester,
    ) async {
      final user = User(
        id: 'partner-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );
      await tester.pumpWidget(
        _createPartnerTestApp(
          isLoggedIn: true,
          currentUser: user,
          onboardingState: const AsyncData(OnboardingState.pendingReview),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerApplyStatusPage), findsOneWidget);
      expect(find.byType(PartnerHomePage), findsNothing);
    });

    // Test 7: needsCorrection → redirected to /apply/status
    testWidgets('needsCorrection: / 접근 시 PartnerApplyStatusPage로 리다이렉트', (
      tester,
    ) async {
      final user = User(
        id: 'partner-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );
      await tester.pumpWidget(
        _createPartnerTestApp(
          isLoggedIn: true,
          currentUser: user,
          onboardingState: const AsyncData(OnboardingState.needsCorrection),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerApplyStatusPage), findsOneWidget);
      expect(find.byType(PartnerHomePage), findsNothing);
    });

    // Test 8: hasPartner + /apply → redirected to /
    testWidgets('hasPartner: /apply 접근 시 홈(PartnerHomePage)으로 리다이렉트', (
      tester,
    ) async {
      final user = User(
        id: 'partner-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );
      await tester.pumpWidget(
        _createPartnerTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/apply',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerHomePage), findsOneWidget);
      expect(find.byType(PartnerApplyPage), findsNothing);
    });

    // Test 9: /dev/* accessible without auth
    testWidgets('비로그인: /dev/user-switch 접근 시 인증 없이 허용', (tester) async {
      await tester.pumpWidget(
        _createPartnerTestApp(initialLocation: '/dev/user-switch'),
      );
      await tester.pump();
      await tester.pump();

      // Should NOT redirect to login
      expect(find.byType(PartnerLoginPage), findsNothing);
    });

    // Test 10: hasPartner → home accessible without redirect
    testWidgets('hasPartner: / 접근 시 리다이렉트 없이 PartnerHomePage 표시', (
      tester,
    ) async {
      final user = User(
        id: 'partner-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );
      await tester.pumpWidget(
        _createPartnerTestApp(
          isLoggedIn: true,
          currentUser: user,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerHomePage), findsOneWidget);
      expect(find.byType(PartnerLoginPage), findsNothing);
    });
  });
}
