import 'dart:async';

import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

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

    testWidgets('로그인 상태: 로그인 복귀 경로가 consent 페이지면 consent 페이지로 돌아간다', (
      tester,
    ) async {
      setKoreanLocale(tester);
      when(
        () => mockConsentRepository.hasRequiredConsents(),
      ).thenAnswer((_) async => false);

      await pumpRouterApp(
        tester,
        currentUser: user,
        initialLocation: '/login?from=%2Fsignup%2Fconsent%3Ffrom%3D%252Fmy',
        consentRepository: mockConsentRepository,
      );

      expect(find.byType(SignupConsentPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
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

    testWidgets('로그인 상태: 동의 조회 에러면 보호 경로를 fail-closed로 동의 페이지에 보낸다', (
      tester,
    ) async {
      setKoreanLocale(tester);
      when(
        () => mockConsentRepository.hasRequiredConsents(),
      ).thenThrow(Exception('consent lookup failed'));

      await pumpRouterApp(
        tester,
        currentUser: user,
        initialLocation: '/my',
        consentRepository: mockConsentRepository,
      );

      // Fix #883: AsyncError with retry causes isLoading && hasError both
      // true — need extra pump for error state to propagate through redirect.
      await tester.pump();

      expect(find.byType(SignupConsentPage), findsOneWidget);
      expect(find.byType(MyPage), findsNothing);
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

    // Fix #970: consent 완료 후 /my에서 back 버튼으로 앱이 종료되던 버그 재발 방지.
    // completeSignup()이 go(/)→push(destination) 패턴을 써야 back stack이 보존된다.
    testWidgets('동의 완료 후 /my에서 back 버튼을 누르면 앱 종료 대신 홈(/)으로 이동한다', (
      tester,
    ) async {
      setKoreanLocale(tester);
      when(
        () => mockConsentRepository.hasRequiredConsents(),
      ).thenAnswer((_) async => true);

      await pumpRouterApp(
        tester,
        currentUser: user,
        initialLocation: '/',
        consentRepository: mockConsentRepository,
      );

      expect(find.byType(HomePage), findsOneWidget);

      // ConsentCoordinator가 completeSignup(from: '/my')를 호출하는 상황을 재현:
      // go('/')로 홈을 스택 바닥에 anchor한 뒤 push('/my')로 목적지로 이동한다.
      final context = tester.element(find.byType(_RouterTestApp));
      final router = ProviderScope.containerOf(context).read(goRouterProvider);
      ConsentCoordinator(router).completeSignup(from: '/my');

      await tester.pumpAndSettle();

      // /my에 도착했는지 확인
      expect(find.byType(MyPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      // Fix #970: back stack에 /가 있으므로 canPop()이 true여야 한다.
      // (이전 버그: go('/my')가 전체 스택을 교체해서 canPop() == false → 앱 종료)
      expect(router.canPop(), isTrue);

      // 실제로 pop해서 홈으로 돌아오는지 확인
      router.pop();
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(MyPage), findsNothing);
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
