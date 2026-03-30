import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget buildSubject({
    VoidCallback? onCancel,
    VoidCallback? onAgree,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: Scaffold(
          body: IdentityVerificationConsentSheet(
            onCancel: onCancel ?? () {},
            onAgree: onAgree ?? () {},
          ),
        ),
      ),
    );
  }

  group('IdentityVerificationConsentSheet', () {
    testWidgets('renders required consent copy', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('본인확인정보 수집·이용 동의'), findsOneWidget);
      expect(find.text('CI'), findsNothing);
      expect(find.text('• CI'), findsOneWidget);
      expect(find.text('• DI'), findsOneWidget);
      expect(find.text('• 이름'), findsOneWidget);
      expect(find.text('• 생년월일'), findsOneWidget);
      expect(find.text('• 성별'), findsOneWidget);
      expect(find.text('• 휴대폰번호'), findsOneWidget);
      expect(find.text('본인확인 및 중복가입 방지를 위해 아래 정보를 수집합니다.'), findsOneWidget);
      expect(find.text('CI/DI는 암호화되어 안전하게 저장됩니다.'), findsOneWidget);
      expect(find.text('동의하고 인증'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
    });

    testWidgets('invokes cancel callback when cancel tapped', (tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        buildSubject(
          onCancel: () {
            cancelled = true;
          },
        ),
      );

      await tester.ensureVisible(find.text('취소'));
      await tester.tap(find.text('취소'));
      await tester.pump();

      expect(cancelled, isTrue);
    });

    testWidgets('invokes agree callback when agree tapped', (tester) async {
      var agreed = false;

      await tester.pumpWidget(
        buildSubject(
          onAgree: () {
            agreed = true;
          },
        ),
      );

      await tester.ensureVisible(find.text('동의하고 인증'));
      await tester.tap(find.text('동의하고 인증'));
      await tester.pump();

      expect(agreed, isTrue);
    });
  });
}
