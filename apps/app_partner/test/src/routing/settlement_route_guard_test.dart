// Fix #1533: settlement 라우트 가드 회귀 테스트.
// UI 숨김(PartnerScaffold)만으로는 딥링크/직접 접근을 막지 못하므로,
// GoRouter redirect에서도 SETTLEMENT_VIEW 권한을 확인하는 경로를 검증한다.
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/mocks.dart';

class _FakeAuthController extends AuthController {
  @override
  Future<void> build() async {}

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

MockPartnerRepository _mockPartnerRepository() {
  final mock = MockPartnerRepository();
  when(mock.getMyApplication).thenAnswer((_) async => null);
  return mock;
}

/// Creates a test router that mirrors the settlement guard from [app_router.dart].
///
/// [settlementAccess] is a [ValueNotifier<bool?>] where:
/// - `null`  = provider is loading (no redirect — refreshListenable will re-eval)
/// - `true`  = data(true)  → access granted
/// - `false` = data(false) → redirect to '/'
///
/// Passing a [ValueNotifier] (instead of a plain bool) lets tests simulate
/// the async loading-then-resolve scenario that the actual router handles via
/// [refreshListenable]. This mirrors the pattern used in partner_redirect_test.dart.
Widget _createSettlementTestApp({
  required bool isLoggedIn,
  required ValueNotifier<bool?> settlementAccess,
  User? currentUser,
  String initialLocation = '/settlement',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: $appRoutes,
    refreshListenable: settlementAccess,
    redirect: (context, state) {
      final path = state.uri.path;

      if (!isLoggedIn && path != '/login') return '/login';
      if (isLoggedIn && path == '/login') return '/';

      // Mirror redirect branch 4 from app_router.dart.
      // Precise path check (== '/settlement' || startsWith('/settlement/')) avoids
      // incorrectly catching sibling paths like '/settlement-history'.
      // loading (null) → no redirect: refreshListenable fires when resolved.
      // data(false)    → redirect to '/'.
      // data(true)     → no redirect.
      if (isLoggedIn &&
          (path == '/settlement' || path.startsWith('/settlement/'))) {
        final access = settlementAccess.value;
        if (access != null && !access) return '/';
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
      onboardingStateProvider.overrideWith(
        (_) async => OnboardingState.hasPartner,
      ),
      partnerRepositoryProvider.overrideWithValue(_mockPartnerRepository()),
    ],
    child: MaterialApp.router(
      theme: MinglitTheme.materialTheme,
      routerConfig: router,
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

User _makeUser() => User(
  id: 'partner-1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime(2026).toIso8601String(),
);

void main() {
  group('Settlement route guard — redirect branch 4 (Fix #1533)', () {
    testWidgets(
      'SETTLEMENT_VIEW 권한 있음: /settlement 접근 허용',
      (tester) async {
        final access = ValueNotifier<bool?>(true);
        addTearDown(access.dispose);

        await tester.pumpWidget(
          _createSettlementTestApp(
            isLoggedIn: true,
            currentUser: _makeUser(),
            settlementAccess: access,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.byType(PartnerHomePage),
          findsNothing,
          reason: 'SETTLEMENT_VIEW 권한 있는 유저는 홈으로 리다이렉트되지 않아야 한다',
        );
      },
    );

    testWidgets(
      'SETTLEMENT_VIEW 권한 없음: /settlement → / 리다이렉트',
      (tester) async {
        final access = ValueNotifier<bool?>(false);
        addTearDown(access.dispose);

        await tester.pumpWidget(
          _createSettlementTestApp(
            isLoggedIn: true,
            currentUser: _makeUser(),
            settlementAccess: access,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.byType(PartnerHomePage),
          findsOneWidget,
          reason: 'SETTLEMENT_VIEW 권한 없는 유저는 홈으로 리다이렉트되어야 한다',
        );
      },
    );

    testWidgets(
      '권한 로딩 중: /settlement 접근 시 차단하지 않고 대기',
      (tester) async {
        // null = loading state
        final access = ValueNotifier<bool?>(null);
        addTearDown(access.dispose);

        await tester.pumpWidget(
          _createSettlementTestApp(
            isLoggedIn: true,
            currentUser: _makeUser(),
            settlementAccess: access,
          ),
        );
        await tester.pump();
        await tester.pump();

        // Must NOT redirect to home while loading
        expect(
          find.byType(PartnerHomePage),
          findsNothing,
          reason:
              'provider 로딩 중에는 홈으로 리다이렉트해서는 안 된다 (refreshListenable가 resolve 후 재평가)',
        );
      },
    );

    testWidgets(
      '권한 로딩 → true로 resolve: /settlement 유지',
      (tester) async {
        final access = ValueNotifier<bool?>(null);
        addTearDown(access.dispose);

        await tester.pumpWidget(
          _createSettlementTestApp(
            isLoggedIn: true,
            currentUser: _makeUser(),
            settlementAccess: access,
          ),
        );
        await tester.pump();
        await tester.pump();

        // Resolve with access granted
        access.value = true;
        await tester.pump();
        await tester.pump();

        expect(
          find.byType(PartnerHomePage),
          findsNothing,
          reason: 'true로 resolve된 권한 있는 유저는 /settlement에 남아야 한다',
        );
      },
    );

    testWidgets(
      '권한 로딩 → false로 resolve: / 리다이렉트',
      (tester) async {
        final access = ValueNotifier<bool?>(null);
        addTearDown(access.dispose);

        await tester.pumpWidget(
          _createSettlementTestApp(
            isLoggedIn: true,
            currentUser: _makeUser(),
            settlementAccess: access,
          ),
        );
        await tester.pump();
        await tester.pump();

        // Loading: no redirect
        expect(find.byType(PartnerHomePage), findsNothing);

        // Resolve with access denied → refreshListenable fires → redirect to /
        access.value = false;
        await tester.pump();
        await tester.pump();

        expect(
          find.byType(PartnerHomePage),
          findsOneWidget,
          reason: 'false로 resolve된 권한 없는 유저는 홈으로 리다이렉트되어야 한다',
        );
      },
    );

    testWidgets(
      '/settlement-history 형제 경로: settlement guard 개입 없음',
      (tester) async {
        final access = ValueNotifier<bool?>(false);
        addTearDown(access.dispose);

        await tester.pumpWidget(
          _createSettlementTestApp(
            isLoggedIn: true,
            currentUser: _makeUser(),
            settlementAccess: access,
            initialLocation: '/settlement-history',
          ),
        );
        await tester.pump();
        await tester.pump();

        // /settlement-history is NOT a settlement sub-route; guard must not fire
        expect(
          find.byType(PartnerHomePage),
          findsNothing,
          reason: 'startsWith 검사가 /settlement-history 형제 경로를 잘못 차단해서는 안 된다',
        );
      },
    );

    testWidgets(
      '비로그인: /settlement 접근 시 auth guard가 처리 (settlement guard 개입 안 함)',
      (tester) async {
        final access = ValueNotifier<bool?>(false);
        addTearDown(access.dispose);

        await tester.pumpWidget(
          _createSettlementTestApp(
            isLoggedIn: false,
            settlementAccess: access,
          ),
        );
        await tester.pump();
        await tester.pump();

        // Should be redirected to login, not home
        expect(find.byType(PartnerHomePage), findsNothing);
      },
    );
  });
}
