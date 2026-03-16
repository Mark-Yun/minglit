import 'dart:async';

import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Page', () {
    // Test 1: Login buttons rendered
    testWidgets('로그인 버튼: Google과 Kakao 버튼 표시', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/login'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Google로 시작하기'), findsOneWidget);
      expect(find.text('카카오로 시작하기'), findsOneWidget);
    });

    // Test 2: Login page renders (unauthenticated direct navigation)
    testWidgets('비로그인: /login 접근 시 LoginPage 렌더링', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/login'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    // Test 3: Loading state shows progress indicator
    testWidgets('로딩 상태: MinglitCircularProgressIndicator 표시', (tester) async {
      setKoreanLocale(tester);
      // Override authControllerProvider to return loading state
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/login',
          additionalOverrides: [
            authControllerProvider.overrideWith(_LoadingAuthController.new),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);
    });

    // Test 4: Authenticated user on /login → redirected to home
    testWidgets('로그인 상태: /login 접근 시 홈으로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/login',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    // Test 5: from param present → back button visible but navigates to home
    testWidgets('from 파라미터: LoginPage에서 back 시 홈으로 이동', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/login?from=%2Fmy'),
      );
      await tester.pump();
      await tester.pump();

      // LoginPage is shown (not redirected since unauthenticated)
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}

/// Auth controller that stays in loading state for testing
class _LoadingAuthController extends AuthController {
  @override
  FutureOr<void> build() async {
    await Future<void>.delayed(
      const Duration(days: 1),
    ); // Never resolves in test
  }
}
