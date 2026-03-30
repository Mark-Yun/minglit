import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/mocks.dart';
import '../../utils/test_utils.dart';

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(
      () => mockRouter.push(any(), extra: any(named: 'extra')),
    ).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  group('AccountDeletionCoordinator', () {
    test('start opens deletion reason route', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(accountDeletionCoordinatorProvider).start();

      verify(
        () => mockRouter.push(
          any(that: contains('delete-account')),
          extra: any(named: 'extra'),
        ),
      ).called(1);
    });

    test('pushInfo keeps custom reason detail out of the URL', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container
          .read(accountDeletionCoordinatorProvider)
          .pushInfo(
            reason: const WithdrawalReason(
              reasonCode: WithdrawalReasonCode.other,
              detail: '민감한 사유',
            ),
          );

      verify(
        () => mockRouter.push(
          any(
            that: allOf(
              contains('delete-account/info'),
              isNot(contains('reason-text')),
            ),
          ),
          extra: '민감한 사유',
        ),
      ).called(1);
    });

    test('goToSettlement navigates to settlement root', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container.read(accountDeletionCoordinatorProvider).goToSettlement();

      verify(() => mockRouter.go('/settlement')).called(1);
    });
  });
}
