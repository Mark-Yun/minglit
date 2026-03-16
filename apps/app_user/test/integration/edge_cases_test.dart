import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/dev/user_dev_map.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter_test/flutter_test.dart';


import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  

  group('Edge Cases', () {
    // Test 1: /explore redirect → home (backward compat)
    testWidgets('/explore 접근 시 홈으로 리다이렉트 (backward compat)', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/explore'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    // Test 2: from=// injection prevention — should redirect to home
    testWidgets('from=//evil.com: injection 방지 — 홈으로 리다이렉트', (tester) async {
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

      expect(find.byType(HomePage), findsOneWidget);
    });

    // Test 3: from=/login loop prevention — should redirect to home
    testWidgets('from=/login: 루프 방지 — 홈으로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/login?from=%2Flogin',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
    });

    // Test 4: /dev bypass — accessible without auth
    testWidgets('/dev 라우트: 비로그인 상태에서도 접근 가능', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/dev'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(UserDevMap), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    // Test 5: /events/:id/apply suffix-match protection
    testWidgets('비로그인: /events/:id/apply suffix-match 보호', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/events/any-id/apply'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    // Test 6: /explore sub-path also redirects to home
    testWidgets('/explore/curation 접근 시 홈으로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/explore/anything'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
