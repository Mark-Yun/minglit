// Fix #2121: AccountManagementPage visual contract — MinglitSettingsGroup 패턴 적용 검증
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/pages/account_management_page.dart';

Widget _buildPage({
  VoidCallback? onLogout,
  VoidCallback? onDeleteAccount,
  VoidCallback? onCertification,
  VoidCallback? onPartnerProfile,
  bool isVerified = false,
}) {
  return MaterialApp(
    home: AccountManagementPage(
      onLogout: onLogout ?? () {},
      onDeleteAccount: onDeleteAccount ?? () {},
      onCertification: onCertification,
      onPartnerProfile: onPartnerProfile,
      isVerified: isVerified,
    ),
  );
}

void main() {
  group('AccountManagementPage', () {
    testWidgets('renders 계정 관리 AppBar and logout/delete tiles',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.text('계정 관리'), findsWidgets);
      expect(find.text('로그아웃'), findsOneWidget);
      expect(find.text('회원 탈퇴'), findsOneWidget);
    });

    testWidgets('hides certification tile when onCertification is null',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.text('본인인증'), findsNothing);
    });

    testWidgets('shows certification tile with 인증하기 when not verified',
        (tester) async {
      await tester.pumpWidget(
        _buildPage(onCertification: () {}, isVerified: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('본인인증'), findsOneWidget);
      expect(find.text('인증하기'), findsOneWidget);
      expect(find.text('인증 완료'), findsNothing);
    });

    testWidgets('shows certification tile with 인증 완료 when verified',
        (tester) async {
      await tester.pumpWidget(
        _buildPage(onCertification: () {}, isVerified: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('본인인증'), findsOneWidget);
      expect(find.text('인증 완료'), findsOneWidget);
      expect(find.text('인증하기'), findsNothing);
    });

    testWidgets('shows partner profile tile when onPartnerProfile is provided',
        (tester) async {
      await tester.pumpWidget(
        _buildPage(onPartnerProfile: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('파트너 프로필'), findsOneWidget);
    });

    testWidgets('hides partner profile tile when onPartnerProfile is null',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.text('파트너 프로필'), findsNothing);
    });

    testWidgets('logout tile invokes onLogout after confirmation',
        (tester) async {
      var called = false;
      await tester.pumpWidget(_buildPage(onLogout: () => called = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('로그아웃 하시겠어요?'), findsOneWidget);

      // Tap the confirm button in the dialog
      final confirmButton = find.text('로그아웃').last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('delete account tile invokes onDeleteAccount directly',
        (tester) async {
      var called = false;
      await tester
          .pumpWidget(_buildPage(onDeleteAccount: () => called = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('회원 탈퇴'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}
