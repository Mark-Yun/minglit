import 'package:app_partner/src/features/verification/verification_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  group('VerificationCoordinator', () {
    test('creates from provider', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final notifier = container.read(
        verificationCoordinatorProvider.notifier,
      );
      expect(notifier, isA<VerificationCoordinator>());
    });

    test('pushVerificationManage calls router.push', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container
          .read(verificationCoordinatorProvider.notifier)
          .pushVerificationManage();

      verify(() => mockRouter.push(any())).called(1);
    });

    test('pushCreateVerification calls router.push', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container
          .read(verificationCoordinatorProvider.notifier)
          .pushCreateVerification(partnerId: 'partner_1');

      verify(() => mockRouter.push(any())).called(1);
    });

    test('pushCreateVerification works without partnerId', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      container
          .read(verificationCoordinatorProvider.notifier)
          .pushCreateVerification();

      verify(() => mockRouter.push(any())).called(1);
    });
  });
}
