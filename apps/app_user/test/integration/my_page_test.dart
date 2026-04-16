import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/golden_capture.dart';
import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  group('MyPage Flow', () {
    // Test 1: Authenticated MyPage content
    testWidgets('로그인 상태: MyPage에서 사용자 이름과 메뉴 표시', (tester) async {
      setKoreanLocale(tester);
      final capture = GoldenCapture('my_u');
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
        ),
      );
      await tester.pump();
      await tester.pump();

      await capture.setup(tester, 0); // 마이페이지 렌더링

      expect(find.byType(MyPage), findsOneWidget);
      expect(find.text('구매 내역'), findsOneWidget);
      expect(find.text('알림 설정'), findsOneWidget);
      // Fix #1213: 로그아웃/회원탈퇴가 계정 관리 서브페이지로 이동 — MyPage에서는 '계정 관리' 항목 확인
      await tester.scrollUntilVisible(find.text('계정 관리'), 100);
      expect(find.text('계정 관리'), findsOneWidget);
    });

    // Test 2: Unauthenticated /my → LoginPage redirect
    testWidgets('비로그인: /my 접근 시 LoginPage로 리다이렉트', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/my'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(MyPage), findsNothing);
    });

    // Test 3: MyPage → 구매 내역 navigation
    testWidgets('로그인 상태: 구매 내역 탭 → PurchaseHistoryPage', (tester) async {
      setKoreanLocale(tester);
      final capture = GoldenCapture('my_u');
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('구매 내역'));
      await tester.pump();
      await tester.pump();

      await capture.after(tester, 1); // 메뉴 항목 표시

      expect(find.byType(PurchaseHistoryPage), findsOneWidget);
    });
  });
}
