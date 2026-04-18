// Fix #1533: settlement 라우트 가드 회귀 테스트.
// UI 숨김(PartnerScaffold)만으로는 딥링크/직접 접근을 막지 못하므로,
// GoRouter redirect에서도 SETTLEMENT_VIEW 권한을 확인하는 경로를 검증한다.
import 'dart:async';

import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

class _MockSession extends Mock implements Session {}

void main() {
  late StreamController<AuthState> authController;
  late User user;
  late _MockSession session;

  setUp(() {
    authController = StreamController<AuthState>.broadcast();
    user = User(
      id: 'partner-test',
      appMetadata: const {
        'provider': 'email',
        'providers': ['email'],
      },
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime(2026).toIso8601String(),
      email: 'partner@test.com',
      identities: const [],
    );
    session = _MockSession();
    when(() => session.user).thenReturn(user);
  });

  tearDown(() async {
    await authController.close();
  });

  Widget buildApp({required bool hasSettlementAccess}) {
    return ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith(
          (_) => authController.stream,
        ),
        currentUserProvider.overrideWith((_) => user),
        onboardingStateProvider.overrideWith(
          (_) async => OnboardingState.hasPartner,
        ),
        hasSettlementAccessProvider.overrideWith(
          (_) async => hasSettlementAccess,
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(goRouterProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('Settlement route guard', () {
    testWidgets(
      '/settlement redirects to / when user lacks SETTLEMENT_VIEW',
      (tester) async {
        await tester.pumpWidget(buildApp(hasSettlementAccess: false));
        await tester.pump();

        final context = tester.element(find.byType(Router).first);
        GoRouter.of(context).go('/settlement');
        await tester.pumpAndSettle();

        final location = GoRouter.of(context).state.uri.path;
        expect(
          location,
          '/',
          reason: 'Staff without SETTLEMENT_VIEW must be redirected to home',
        );
      },
    );

    testWidgets(
      '/settlement/bank-account redirects to / when user lacks SETTLEMENT_VIEW',
      (tester) async {
        await tester.pumpWidget(buildApp(hasSettlementAccess: false));
        await tester.pump();

        final context = tester.element(find.byType(Router).first);
        GoRouter.of(context).go('/settlement/bank-account');
        await tester.pumpAndSettle();

        final location = GoRouter.of(context).state.uri.path;
        expect(
          location,
          '/',
          reason:
              'Bank account sub-route must be blocked without SETTLEMENT_VIEW',
        );
      },
    );

    testWidgets(
      '/settlement/:id redirects to / when user lacks SETTLEMENT_VIEW',
      (tester) async {
        await tester.pumpWidget(buildApp(hasSettlementAccess: false));
        await tester.pump();

        final context = tester.element(find.byType(Router).first);
        GoRouter.of(context).go('/settlement/some-id-123');
        await tester.pumpAndSettle();

        final location = GoRouter.of(context).state.uri.path;
        expect(
          location,
          '/',
          reason:
              'Settlement detail route must be blocked without SETTLEMENT_VIEW',
        );
      },
    );

    testWidgets(
      '/settlement is accessible when user has SETTLEMENT_VIEW',
      (tester) async {
        await tester.pumpWidget(buildApp(hasSettlementAccess: true));
        await tester.pump();

        final context = tester.element(find.byType(Router).first);
        GoRouter.of(context).go('/settlement');
        await tester.pumpAndSettle();

        final location = GoRouter.of(context).state.uri.path;
        expect(
          location,
          '/settlement',
          reason: 'User with SETTLEMENT_VIEW must reach settlement page',
        );
      },
    );
  });
}
