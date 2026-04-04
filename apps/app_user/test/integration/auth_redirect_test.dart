import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  group('Auth Redirect Flow', () {
    // Test 1: Unauthenticated → /my (protected prefix) → LoginPage
    testWidgets('비로그인: /my 접근 시 LoginPage로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/my'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    // Test 2: Unauthenticated → /purchase-history (protected prefix) → LoginPage
    testWidgets('비로그인: /purchase-history 접근 시 LoginPage로 리다이렉트', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/purchase-history'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    // Test 3: Unauthenticated → /events/test-id/apply (protected suffix) → LoginPage
    testWidgets('비로그인: /events/:id/apply 접근 시 LoginPage로 리다이렉트', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/events/test-event-id/apply'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    // Test 4: Authenticated → /login → redirected to home
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

    // Test 5: Public route accessible without auth
    testWidgets('비로그인: public 라우트(/) 접근 시 리다이렉트 없음', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    // Test 6: from parameter validation — /login?from=// (injection attempt) → home
    testWidgets('로그인 상태: from=//evil.com 은 홈으로 리다이렉트 (injection 방지)', (
      tester,
    ) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/login?from=%2F%2Fevil.com',
        ),
      );
      await tester.pump();
      await tester.pump();

      // Should redirect to home, NOT to //evil.com
      expect(find.byType(HomePage), findsOneWidget);
    });

    // Fix #1000: /tickets/my was missing from protected-prefix coverage.
    testWidgets('비로그인: /tickets/my 접근 시 LoginPage로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/tickets/my'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    // Fix #1000: /certification was missing from protected-prefix coverage.
    testWidgets('비로그인: /certification 접근 시 LoginPage로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/certification'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
