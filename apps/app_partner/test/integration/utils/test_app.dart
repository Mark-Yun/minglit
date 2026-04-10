import 'dart:async';

import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/mocks.dart';

export 'package:app_partner/src/logic/onboarding_state_provider.dart'
    show OnboardingState;

/// Integration test용 파트너 앱 TestApp 헬퍼.
/// 실제 Supabase/Firebase 없이 GoRouter 네비게이션을 테스트합니다.
///
/// app_partner 라우터 redirect 로직을 미러링하여 Supabase 없이
/// 온보딩 상태별 라우팅 동작을 검증합니다.
Widget createPartnerTestApp({
  bool isLoggedIn = false,
  User? currentUser,
  OnboardingState onboardingState = OnboardingState.hasPartner,
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

      if (isLoggedIn) {
        if (!isApplyPage &&
            !isWelcomePage &&
            onboardingState == OnboardingState.needsApplication) {
          return '/welcome';
        }
        if (!isApplyPage &&
            !isWelcomePage &&
            onboardingState == OnboardingState.draftInProgress) {
          return '/apply';
        }
        if (isWelcomePage &&
            onboardingState != OnboardingState.needsApplication) {
          return onboardingState == OnboardingState.draftInProgress
              ? '/apply'
              : '/';
        }
        if (!isApplyPage &&
            !isWelcomePage &&
            (onboardingState == OnboardingState.pendingReview ||
                onboardingState == OnboardingState.needsCorrection)) {
          return '/apply/status';
        }
        if (isApplyPage && onboardingState == OnboardingState.hasPartner) {
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
      onboardingStateProvider.overrideWith((_) async => onboardingState),
      // Fix #1026: prevent PartnerApplyPage from accessing Supabase
      partnerRepositoryProvider.overrideWithValue(_mockPartnerRepository()),
      ...additionalOverrides.cast(),
    ],
    child: MaterialApp.router(
      theme: MinglitTheme.materialTheme,
      routerConfig: testRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

MockPartnerRepository _mockPartnerRepository() {
  final mock = MockPartnerRepository();
  when(mock.getMyApplication).thenAnswer((_) async => null);
  return mock;
}

/// Fake AuthController — no-op stub that never calls authRepositoryProvider.
/// Fix #1073: overriding only build() was insufficient because action methods
/// (signOut, signIn*) call ref.read(authRepositoryProvider) which transitively
/// reads authConfigProvider (throws UnimplementedError if not overridden).
class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signInWithGoogle({String? redirectTo}) async {}

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithApple({String? redirectTo}) async {}

  @override
  Future<void> signInWithKakao({String? redirectTo}) async {}
}
