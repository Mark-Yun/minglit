import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  testWidgets('탈퇴 완료 메시지와 확인 버튼을 렌더링한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const DeletionCompletePage(),
        ),
      ),
    );

    expect(find.text('탈퇴 요청이 완료됐어요'), findsOneWidget);
    expect(find.textContaining('7일 안에 다시 로그인하면 계정을 복구'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });
}
