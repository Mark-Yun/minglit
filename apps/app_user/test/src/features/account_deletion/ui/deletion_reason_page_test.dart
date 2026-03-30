import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  testWidgets('6개 탈퇴 사유를 렌더링하고 기타 선택 시 입력 필드를 노출한다', (
    tester,
  ) async {
    final coordinator = _FakeAccountDeletionCoordinator();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const DeletionReasonPage(),
        ),
      ),
    );

    expect(find.text('더 이상 쓰지 않아요'), findsOneWidget);
    expect(find.text('원하는 이벤트가 없어요'), findsOneWidget);
    expect(find.text('다른 서비스를 이용 중이에요'), findsOneWidget);
    expect(find.text('개인정보가 걱정돼요'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('앱 사용이 어려워요'), 200);
    expect(find.text('앱 사용이 어려워요'), findsOneWidget);
    expect(find.text('직접 입력할게요'), findsOneWidget);
    expect(find.text('상세 사유'), findsNothing);

    await tester.tap(find.text('직접 입력할게요'));
    await tester.pumpAndSettle();

    expect(find.text('상세 사유'), findsOneWidget);
  });

  testWidgets('사유 선택 후 다음을 누르면 coordinator로 reason이 전달된다', (
    tester,
  ) async {
    final coordinator = _FakeAccountDeletionCoordinator();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const DeletionReasonPage(),
        ),
      ),
    );

    await tester.tap(find.text('개인정보가 걱정돼요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(
      coordinator.lastReason?.reasonCode,
      WithdrawalReasonCode.privacyConcern,
    );
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

  WithdrawalReason? lastReason;

  @override
  void pushInfo({WithdrawalReason? reason}) {
    lastReason = reason;
  }
}
