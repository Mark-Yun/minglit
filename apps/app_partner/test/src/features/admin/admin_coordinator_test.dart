import 'package:app_partner/src/features/admin/admin_coordinator.dart';
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

  group('AdminCoordinator', () {
    test('creates from provider', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final notifier = container.read(adminCoordinatorProvider.notifier);
      expect(notifier, isA<AdminCoordinator>());
    });

    test('goToApplicationDetail calls router.push with ID', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final notifier = container.read(adminCoordinatorProvider.notifier);
      notifier.goToApplicationDetail('app_123');

      verify(
        () => mockRouter.push(any(that: contains('app_123'))),
      ).called(1);
    });
  });
}
