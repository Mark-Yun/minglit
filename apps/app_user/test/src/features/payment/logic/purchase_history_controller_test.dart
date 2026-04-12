import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

/// Helper: build a minimal [Event] with the given [startTime].
Event _makeEvent({required DateTime startTime}) {
  final now = DateTime.now();
  return Event(
    id: 'evt1',
    partyId: 'party1',
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 3)),
    createdAt: now,
    updatedAt: now,
  );
}

/// Helper: build a minimal [EventApplication] with the given [event] and
/// optional overrides.
EventApplication _makeApplication({
  required Event event,
  String status = 'paid',
  String refundStatus = 'none',
  String? paymentId = 'pay_123',
  int? paymentAmount = 10000,
}) {
  final now = DateTime.now();
  return EventApplication(
    id: 'app1',
    eventId: event.id,
    ticketId: 'ticket1',
    userId: 'user1',
    status: status,
    refundStatus: refundStatus,
    paymentId: paymentId,
    paymentAmount: paymentAmount,
    createdAt: now,
    updatedAt: now,
    event: event,
  );
}

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

  // Fix #1235: canCancel must respect event startTime.
  group('PurchaseHistoryController.canCancel — Fix #1235', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
    });

    tearDown(() => container.dispose());

    PurchaseHistoryController getController() =>
        container.read(purchaseHistoryControllerProvider.notifier);

    test('canCancel returns true when event has not started yet', () {
      final futureEvent = _makeEvent(
        startTime: DateTime.now().add(const Duration(hours: 24)),
      );
      final application = _makeApplication(event: futureEvent);

      expect(getController().canCancel(application), isTrue);
    });

    test('canCancel returns false when event has already started', () {
      final pastEvent = _makeEvent(
        startTime: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final application = _makeApplication(event: pastEvent);

      expect(getController().canCancel(application), isFalse);
    });

    test(
      'canCancel returns false when event started in the past (hours ago)',
      () {
        final pastEvent = _makeEvent(
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
        );
        final application = _makeApplication(event: pastEvent);

        expect(getController().canCancel(application), isFalse);
      },
    );

    test(
      'canCancel returns false when application status is not paid/approved',
      () {
        final futureEvent = _makeEvent(
          startTime: DateTime.now().add(const Duration(hours: 24)),
        );
        final application = _makeApplication(
          event: futureEvent,
          status: 'cancelled',
        );

        expect(getController().canCancel(application), isFalse);
      },
    );

    test('canCancel returns false when refundStatus is not "none"', () {
      final futureEvent = _makeEvent(
        startTime: DateTime.now().add(const Duration(hours: 24)),
      );
      final application = _makeApplication(
        event: futureEvent,
        refundStatus: 'completed',
      );

      expect(getController().canCancel(application), isFalse);
    });

    test('canCancel returns false when event is null (no event info)', () {
      final now = DateTime.now();
      final application = EventApplication(
        id: 'app2',
        eventId: 'event2',
        ticketId: 'ticket2',
        userId: 'user2',
        status: 'paid',
        paymentId: 'pay_456',
        paymentAmount: 10000,
        createdAt: now,
        updatedAt: now,
        // event intentionally omitted (null)
      );

      expect(getController().canCancel(application), isFalse);
    });

    test(
      'canCancel returns true for "approved" status before event starts',
      () {
        final futureEvent = _makeEvent(
          startTime: DateTime.now().add(const Duration(hours: 1)),
        );
        final application = _makeApplication(
          event: futureEvent,
          status: 'approved',
        );

        expect(getController().canCancel(application), isTrue);
      },
    );
  });

  // Fix #1287: PurchaseHistoryController 에러 경로 테스트
  group('PurchaseHistoryController — error paths (Fix #1287)', () {
    test(
      'build error field is set when getMyPurchaseHistory throws',
      () async {
        const userId = 'test_user_id';
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn(userId);

        when(
          () => mockEventRepository.getMyPurchaseHistory(userId),
        ).thenThrow(Exception('History fetch failed'));

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
          ],
        );
        addTearDown(container.dispose);

        // Subscribe to keep the provider alive while we wait for completion
        final sub = container.listen(
          purchaseHistoryControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        await container
            .read(purchaseHistoryControllerProvider.future)
            // ignore: avoid_catches_without_on_clauses
            .catchError((_) {});

        final state = container.read(purchaseHistoryControllerProvider);
        expect(state.error, isA<Exception>());
      },
    );

    test(
      'build error is the original exception when getMyPurchaseHistory throws',
      () async {
        const userId = 'test_user_id';
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn(userId);

        final specificException = Exception('Network timeout');
        when(
          () => mockEventRepository.getMyPurchaseHistory(userId),
        ).thenThrow(specificException);

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          purchaseHistoryControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        await container
            .read(purchaseHistoryControllerProvider.future)
            // ignore: avoid_catches_without_on_clauses
            .catchError((_) {});

        final state = container.read(purchaseHistoryControllerProvider);
        expect(state.error, equals(specificException));
      },
    );

    test(
      'isRefundReady returns false when paymentId is null',
      () {
        final futureEvent = _makeEvent(
          startTime: DateTime.now().add(const Duration(hours: 24)),
        );
        final application = _makeApplication(
          event: futureEvent,
          paymentId: null,
        );

        final testContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
          ],
        );
        addTearDown(testContainer.dispose);

        final ctrl = testContainer.read(
          purchaseHistoryControllerProvider.notifier,
        );
        expect(ctrl.isRefundReady(application), isFalse);
      },
    );

    test(
      'isRefundReady returns false when paymentAmount is null',
      () {
        final futureEvent = _makeEvent(
          startTime: DateTime.now().add(const Duration(hours: 24)),
        );
        final application = _makeApplication(
          event: futureEvent,
          paymentAmount: null,
        );

        final testContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
          ],
        );
        addTearDown(testContainer.dispose);

        final ctrl = testContainer.read(
          purchaseHistoryControllerProvider.notifier,
        );
        expect(ctrl.isRefundReady(application), isFalse);
      },
    );

    test(
      'canCancel returns false when isRefundReady is false (null paymentId)',
      () {
        final futureEvent = _makeEvent(
          startTime: DateTime.now().add(const Duration(hours: 24)),
        );
        final application = _makeApplication(
          event: futureEvent,
          paymentId: null,
        );

        final testContainer = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
          ],
        );
        addTearDown(testContainer.dispose);

        final ctrl = testContainer.read(
          purchaseHistoryControllerProvider.notifier,
        );
        expect(ctrl.canCancel(application), isFalse);
      },
    );
  });
}
