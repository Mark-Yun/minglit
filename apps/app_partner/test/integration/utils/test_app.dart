import 'dart:async';

import 'package:app_partner/src/features/onboarding/partner_apply_page.dart'
    show PartnerApplyPage;
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/mocks.dart';

/// Creates an integration test app for the partner app.
/// Mirrors the redirect logic from [app_partner/src/routing/app_router.dart]
/// without requiring Supabase or Firebase.
///
/// [additionalOverrides] allows callers to inject page-specific provider
/// overrides (e.g. repository stubs, controller fakes).
Widget createPartnerTestApp({
  bool isLoggedIn = true,
  User? currentUser,
  AsyncValue<OnboardingState> onboardingState = const AsyncData(
    OnboardingState.hasPartner,
  ),
  String initialLocation = '/',
  List<dynamic> additionalOverrides = const [],
}) {
  final testRouter = GoRouter(
    initialLocation: initialLocation,
    routes: $appRoutes,
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggingIn = path == '/login';
      final isApplyPage = path.startsWith('/apply');
      final isWelcomePage = path == '/welcome';

      if (path.startsWith('/dev')) return null;

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';

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
        if (isApplyPage && state_ == OnboardingState.hasPartner) return '/';
      }

      return null;
    },
  );

  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((_) => currentUser),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      authControllerProvider.overrideWith(FakePartnerAuthController.new),
      notificationInitializerProvider.overrideWith((_) {}),
      onboardingStateProvider.overrideWith((_) async {
        if (onboardingState.hasValue) return onboardingState.value!;
        throw StateError('loading');
      }),
      partnerRepositoryProvider.overrideWithValue(
        _createDefaultPartnerRepository(),
      ),
      ...additionalOverrides.cast(),
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

/// Minimal stub so [PartnerApplyPage.initState] never touches Supabase.
MockPartnerRepository _createDefaultPartnerRepository() {
  final mock = MockPartnerRepository();
  when(mock.getMyApplication).thenAnswer((_) async => null);
  return mock;
}

/// No-op AuthController — avoids Supabase calls in integration tests.
class FakePartnerAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}
