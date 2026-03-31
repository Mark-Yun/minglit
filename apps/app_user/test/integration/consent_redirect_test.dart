import 'dart:async';

import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/test_mocks.dart';
import 'utils/test_app.dart';

class MockConsentRepository extends Mock implements ConsentRepository {}

void main() {
  group('Signup Consent Redirect Flow', () {
    late MockConsentRepository mockConsentRepository;
    late User user;

    setUp(() {
      mockConsentRepository = MockConsentRepository();
      user = createMockUserForTest();

      when(
        () => mockConsentRepository.getConsents(any()),
      ).thenAnswer((_) async => []);
    });

    testWidgets('비로그인: /signup/consent 접근 시 LoginPage로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      when(
        () => mockConsentRepository.hasRequiredConsents(),
      ).thenAnswer((_) async => false);

      await pumpRouterApp(
        tester,
        currentUser: null,
        initialLocation: '/signup/consent',
        consentRepository: mockConsentRepository,
      );

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(SignupConsentPage), findsNothing);
    });

    testWidgets('로그인 상태: 미동의로 보호 경로 접근 시 동의 페이지로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      when(
        () => mockConsentRepository.hasRequiredConsents(),
      ).thenAnswer((_) async => false);

      await pumpRouterApp(
        tester,
        currentUser: user,
        initialLocation: '/my',
        consentRepository: mockConsentRepository,
      );

      expect(find.byType(SignupConsentPage), findsOneWidget);
      expect(find.byType(MyPage), findsNothing);
    });

    testWidgets('로그인 상태: 동의 페이지 자체에서는 redirect loop가 발생하지 않는다', (tester) async {
      setKoreanLocale(tester);
      when(
        () => mockConsentRepository.hasRequiredConsents(),
      ).thenAnswer((_) async => false);

      await pumpRouterApp(
        tester,
        currentUser: user,
        initialLocation: '/signup/consent?from=%2Fmy',
        consentRepository: mockConsentRepository,
      );

      expect(find.byType(SignupConsentPage), findsOneWidget);
    });

    testWidgets('로그인 상태: 동의 여부 로딩 중이면 보호 경로 리다이렉트를 건너뛴다', (tester) async {
      setKoreanLocale(tester);
      final completer = Completer<bool>();
      when(
        () => mockConsentRepository.hasRequiredConsents(),
      ).thenAnswer((_) => completer.future);

      await pumpRouterApp(
        tester,
        currentUser: user,
        initialLocation: '/my',
        consentRepository: mockConsentRepository,
      );

      expect(find.byType(MyPage), findsOneWidget);
      expect(find.byType(SignupConsentPage), findsNothing);
    });

    testWidgets('로그인 상태: 동의 완료 후 /signup/consent 접근 시 원래 경로로 복귀', (
      tester,
    ) async {
      setKoreanLocale(tester);
      when(
        () => mockConsentRepository.hasRequiredConsents(),
      ).thenAnswer((_) async => true);

      await pumpRouterApp(
        tester,
        currentUser: user,
        initialLocation: '/signup/consent?from=%2Fmy',
        consentRepository: mockConsentRepository,
      );

      expect(find.byType(MyPage), findsOneWidget);
      expect(find.byType(SignupConsentPage), findsNothing);
    });
  });
}

Future<void> pumpRouterApp(
  WidgetTester tester, {
  required User? currentUser,
  required String initialLocation,
  required ConsentRepository consentRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => currentUser),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        authControllerProvider.overrideWith(_FakeAuthController.new),
        consentRepositoryProvider.overrideWithValue(consentRepository),
        notificationInitializerProvider.overrideWith((_) {}),
        recommendationEventsProvider.overrideWith((_) async => <Event>[]),
        eventFeedProvider.overrideWith((ref, arg) async => <Event>[]),
        activeFiltersProvider.overrideWith(_NoFiltersNotifier.new),
      ],
      child: const _RouterTestApp(),
    ),
  );

  await tester.pump();

  final context = tester.element(find.byType(_RouterTestApp));
  ProviderScope.containerOf(context).read(goRouterProvider).go(initialLocation);

  await tester.pump();
  await tester.pump();
}

class _RouterTestApp extends ConsumerWidget {
  const _RouterTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: MinglitTheme.materialTheme,
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}

class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}

class _NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}
