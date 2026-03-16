import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  group('Login Page', () {
    testWidgets('비로그인: /login 접근 시 LoginPage 렌더링', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/login'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('로그인 상태: /login 접근 시 홈으로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(createTestApp(isLoggedIn: true, currentUser: user, initialLocation: '/login'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('from 파라미터: LoginPage 렌더링 (비로그인)', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/login?from=%2Fmy'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
