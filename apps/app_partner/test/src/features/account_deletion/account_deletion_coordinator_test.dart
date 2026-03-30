import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/mocks.dart';
import '../../utils/test_utils.dart';

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
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
        () => mockRouter.push(any(that: contains('delete-account'))),
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
