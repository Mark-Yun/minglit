import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  late MockEventRepository mockEventRepository;

  setUp(() {
    mockEventRepository = MockEventRepository();
  });

  group('PurchaseHistoryController', () {
    test('build returns empty list when user is not logged in', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        purchaseHistoryControllerProvider.future,
      );
      expect(result, isEmpty);
    });

    test('build fetches history when user is logged in', () async {
      const userId = 'test_user_id';
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);

      final mockHistory = [
        EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: userId,
          status: 'paid',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
        ),
      ];

      when(
        () => mockEventRepository.getMyPurchaseHistory(userId),
      ).thenAnswer((_) async => mockHistory);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        purchaseHistoryControllerProvider.future,
      );
      expect(result, mockHistory);
    });
  });
}
