import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/pages/account_management_page.dart';

void main() {
  Widget wrap({
    required VoidCallback onLogout,
    VoidCallback? onDeleteAccount,
  }) {
    return MaterialApp(
      home: AccountManagementPage(
        onLogout: onLogout,
        onDeleteAccount: onDeleteAccount ?? () {},
      ),
    );
  }

  group('AccountManagementPage logout confirm', () {
    testWidgets('로그아웃 탭 시 확인 다이얼로그 표시', (tester) async {
      var logoutCalled = false;
      await tester.pumpWidget(
        wrap(onLogout: () => logoutCalled = true),
      );

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      // 다이얼로그가 표시되고 로그아웃은 아직 실행되지 않음
      expect(find.text('로그아웃 하시겠어요?'), findsOneWidget);
      expect(logoutCalled, isFalse);
    });

    testWidgets('확인 시 onLogout 실행', (tester) async {
      var logoutCalled = false;
      await tester.pumpWidget(
        wrap(onLogout: () => logoutCalled = true),
      );

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      // 다이얼로그에서 '로그아웃' 확인 버튼 탭
      final confirmButtons = find.text('로그아웃');
      // 두 번째 '로그아웃' 텍스트가 다이얼로그 확인 버튼
      await tester.tap(confirmButtons.last);
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });

    testWidgets('취소 시 onLogout 미실행', (tester) async {
      var logoutCalled = false;
      await tester.pumpWidget(
        wrap(onLogout: () => logoutCalled = true),
      );

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(logoutCalled, isFalse);
      // 다이얼로그가 닫히고 페이지가 유지됨
      expect(find.text('로그아웃'), findsOneWidget);
    });
  });
}
