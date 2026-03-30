import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  testWidgets('탈퇴 안내 페이지의 핵심 정보가 표시된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionCoordinatorProvider.overrideWithValue(
            _FakeAccountDeletionCoordinator(),
          ),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const DeletionInfoPage(
            reasonCode: 'privacy_concern',
            reasonText: '개인정보가 걱정돼요',
          ),
        ),
      ),
    );

    expect(find.text('선택한 탈퇴 사유'), findsOneWidget);
    expect(find.text('삭제되는 정보'), findsOneWidget);
    expect(find.text('법정 보존 정보'), findsOneWidget);
    expect(find.text('계속 진행'), findsOneWidget);
  });
}

class _FakeAccountDeletionCoordinator extends AccountDeletionCoordinator {
  _FakeAccountDeletionCoordinator()
    : super(
        GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
      );
}
