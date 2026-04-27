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

        await pumpEventQueue();

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

        await pumpEventQueue();

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
        // paymentId=null but paymentAmount=10000 (paid ticket without ID → invalid)
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

  // Fix #1652: 무료 티켓(paymentAmount=0, paymentId=null) 취소 버튼 표시
  group('PurchaseHistoryController.canCancel — Fix #1652 free ticket', () {
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

    test(
      'canCancel returns true for free ticket (paymentAmount=0, paymentId=null) before event',
      () {
        final futureEvent = _makeEvent(
          startTime: DateTime.now().add(const Duration(hours: 24)),
        );
        final application = _makeApplication(
          event: futureEvent,
          paymentId: null,
          paymentAmount: 0,
        );

        expect(getController().canCancel(application), isTrue);
      },
    );

    test(
      'canCancel returns false for free ticket after event has started',
      () {
        final pastEvent = _makeEvent(
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        final application = _makeApplication(
          event: pastEvent,
          paymentId: null,
          paymentAmount: 0,
        );

        expect(getController().canCancel(application), isFalse);
      },
    );

    test(
      'canCancel returns false for free ticket with paymentAmount=null when event null',
      () {
        final now = DateTime.now();
        final application = EventApplication(
          id: 'app_free',
          eventId: 'event_free',
          ticketId: 'ticket_free',
          userId: 'user_free',
          status: 'paid',
          createdAt: now,
          updatedAt: now,
          // event intentionally omitted
        );

        expect(getController().canCancel(application), isFalse);
      },
    );

    test(
      'canCancel returns false for damaged data (paymentAmount=null) even with valid future event',
      () {
        // Fix #1652: paymentAmount=null is damaged data, not a free ticket.
        // isFree requires paymentAmount == 0 explicitly to prevent treating
        // missing data as free and bypassing payment gateway in user-cancel-order.
        final futureEvent = _makeEvent(
          startTime: DateTime.now().add(const Duration(hours: 24)),
        );
        final now = DateTime.now();
        final application = EventApplication(
          id: 'app_damaged',
          eventId: 'event_damaged',
          ticketId: 'ticket_damaged',
          userId: 'user_damaged',
          status: 'paid',
          createdAt: now,
          updatedAt: now,
          event: futureEvent,
        );

        expect(getController().canCancel(application), isFalse);
      },
    );

    test(
      'canCancel returns false for paid ticket with null paymentId (amount mismatch)',
      () {
        final futureEvent = _makeEvent(
          startTime: DateTime.now().add(const Duration(hours: 24)),
        );
        // paymentId=null but amount=5000 — paid ticket missing ID is not free
        final application = _makeApplication(
          event: futureEvent,
          paymentId: null,
          paymentAmount: 5000,
        );

        expect(getController().canCancel(application), isFalse);
      },
    );
  });

  // Fix #1951: runRefundFlow unit tests — refund calculation edge cases
  group('PurchaseHistoryController.runRefundFlow', () {
    late MockEventRepository mockEventRepo;

    setUp(() {
      mockEventRepo = MockEventRepository();
    });

    ProviderContainer makeContainer({PolicyRepository? policyRepo}) {
      final c = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
          if (policyRepo != null)
            policyRepositoryProvider.overrideWithValue(policyRepo),
        ],
      );
      // Fix #1951: _requestRefund calls ref.invalidate(purchaseHistoryControllerProvider)
      // on itself. Without a listener the AutoDispose provider is immediately
      // disposed, causing the try-block to throw before onSuccess() runs.
      // A listener keeps the provider alive so invalidate triggers a rebuild.
      c.listen(purchaseHistoryControllerProvider, (_, _) {});
      return c;
    }

    PurchaseHistoryController getCtrl(ProviderContainer c) =>
        c.read(purchaseHistoryControllerProvider.notifier);

    test(
      'policy fetch failure uses fallback gracePeriodHours=2 cutoffDays=7 — flow continues',
      () async {
        final container = makeContainer(
          policyRepo: const _ThrowingPolicyRepository(),
        );
        addTearDown(container.dispose);

        var confirmCalled = false;
        RefundCalculation? received;

        // paidAt 1h ago: clearly within 2h grace period fallback
        // event 8d away: clearly within 7d cutoff fallback
        await getCtrl(container).runRefundFlow(
          eventId: 'evt1',
          paymentId: 'pay_123',
          paymentAmount: 10000,
          eventStartTime: DateTime.now().add(const Duration(days: 8)),
          paidAt: DateTime.now().subtract(const Duration(hours: 1)),
          showMissingInfo: () async {},
          showNotEligible: () async {
            fail('should not call showNotEligible');
          },
          confirmRefund: (calc) async {
            confirmCalled = true;
            received = calc;
            return false; // cancel at confirmation — no need to mock cancelOrder
          },
          showError: (msg) async => false,
          onSuccess: () async {},
        );

        expect(confirmCalled, isTrue);
        expect(received?.refundPercentage, equals(100));
      },
    );

    test(
      'policy fetch failure uses fallback — outside grace and cutoff calls showNotEligible',
      () async {
        final container = makeContainer(
          policyRepo: const _ThrowingPolicyRepository(),
        );
        addTearDown(container.dispose);

        var notEligibleCalled = false;

        // paidAt 3d ago: outside 2h grace period fallback
        // event 2d away: outside 7d cutoff fallback
        await getCtrl(container).runRefundFlow(
          eventId: 'evt1',
          paymentId: 'pay_123',
          paymentAmount: 10000,
          eventStartTime: DateTime.now().add(const Duration(days: 2)),
          paidAt: DateTime.now().subtract(const Duration(days: 3)),
          showMissingInfo: () async {},
          showNotEligible: () async {
            notEligibleCalled = true;
          },
          confirmRefund: (calc) async => false,
          showError: (msg) async => false,
          onSuccess: () async {},
        );

        expect(notEligibleCalled, isTrue);
      },
    );

    test(
      'free ticket (paymentAmount=0, paymentId=null) skips refund calculation',
      () async {
        when(
          () => mockEventRepo.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) async => const CancelOrderResult(type: 'cancelled'));

        final container = makeContainer();
        addTearDown(container.dispose);

        var confirmCalled = false;
        RefundCalculation? receivedCalc;
        var onSuccessCalled = false;

        await getCtrl(container).runRefundFlow(
          eventId: 'evt_free',
          paymentId: null,
          paymentAmount: 0,
          eventStartTime: DateTime.now().add(const Duration(days: 1)),
          paidAt: null,
          showMissingInfo: () async {
            fail('should not call showMissingInfo');
          },
          showNotEligible: () async {
            fail('should not call showNotEligible');
          },
          confirmRefund: (calc) async {
            confirmCalled = true;
            receivedCalc = calc;
            return true;
          },
          showError: (msg) async => false,
          onSuccess: () async {
            onSuccessCalled = true;
          },
        );

        expect(confirmCalled, isTrue);
        expect(receivedCalc?.refundPercentage, equals(100));
        expect(receivedCalc?.refundAmount, equals(0));
        expect(receivedCalc?.feeAmount, equals(0));
        expect(onSuccessCalled, isTrue);
      },
    );

    test('free ticket without eventStartTime calls showMissingInfo', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      var missingInfoCalled = false;

      await getCtrl(container).runRefundFlow(
        eventId: 'evt_free',
        paymentId: null,
        paymentAmount: 0,
        eventStartTime: null, // missing
        paidAt: null,
        showMissingInfo: () async {
          missingInfoCalled = true;
        },
        showNotEligible: () async {},
        confirmRefund: (calc) async => false,
        showError: (msg) async => false,
        onSuccess: () async {},
      );

      expect(missingInfoCalled, isTrue);
    });

    test('paid ticket with null paymentId calls showMissingInfo', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      var missingInfoCalled = false;

      await getCtrl(container).runRefundFlow(
        eventId: 'evt1',
        paymentId: null, // missing paymentId for paid ticket
        paymentAmount: 10000,
        eventStartTime: DateTime.now().add(const Duration(days: 8)),
        paidAt: DateTime.now().subtract(const Duration(hours: 1)),
        showMissingInfo: () async {
          missingInfoCalled = true;
        },
        showNotEligible: () async {},
        confirmRefund: (calc) async => false,
        showError: (msg) async => false,
        onSuccess: () async {},
      );

      expect(missingInfoCalled, isTrue);
    });

    test('user cancels at confirmation does not call cancelOrder', () async {
      final container = makeContainer(
        policyRepo: const _StaticPolicyRepository(
          gracePeriodHours: 2,
          cutoffDays: 7,
        ),
      );
      addTearDown(container.dispose);

      await getCtrl(container).runRefundFlow(
        eventId: 'evt1',
        paymentId: 'pay_123',
        paymentAmount: 10000,
        eventStartTime: DateTime.now().add(const Duration(days: 8)),
        paidAt: DateTime.now().subtract(const Duration(hours: 1)),
        showMissingInfo: () async {},
        showNotEligible: () async {},
        confirmRefund: (calc) async => false, // user cancels
        showError: (msg) async => false,
        onSuccess: () async {},
      );

      verifyNever(
        () => mockEventRepo.cancelOrder(
          eventId: any(named: 'eventId'),
          reason: any(named: 'reason'),
        ),
      );
    });

    test('successful refund calls cancelOrder and onSuccess', () async {
      when(
        () => mockEventRepo.cancelOrder(
          eventId: 'evt1',
          reason: '사용자 예매 취소',
        ),
      ).thenAnswer(
        (_) async =>
            const CancelOrderResult(type: 'refunded', refundAmount: 10000),
      );

      final container = makeContainer(
        policyRepo: const _StaticPolicyRepository(
          gracePeriodHours: 2,
          cutoffDays: 7,
        ),
      );
      addTearDown(container.dispose);

      var onSuccessCalled = false;

      await getCtrl(container).runRefundFlow(
        eventId: 'evt1',
        paymentId: 'pay_123',
        paymentAmount: 10000,
        eventStartTime: DateTime.now().add(const Duration(days: 8)),
        paidAt: DateTime.now().subtract(const Duration(hours: 1)),
        showMissingInfo: () async {},
        showNotEligible: () async {},
        confirmRefund: (calc) async => true,
        showError: (msg) async => false,
        onSuccess: () async {
          onSuccessCalled = true;
        },
      );

      verify(
        () => mockEventRepo.cancelOrder(eventId: 'evt1', reason: '사용자 예매 취소'),
      ).called(1);
      expect(onSuccessCalled, isTrue);
    });

    test(
      'cancelOrder failure shows error and does not call onSuccess on no-retry',
      () async {
        when(
          () => mockEventRepo.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        ).thenThrow(Exception('Network error'));

        final container = makeContainer(
          policyRepo: const _StaticPolicyRepository(
            gracePeriodHours: 2,
            cutoffDays: 7,
          ),
        );
        addTearDown(container.dispose);

        var showErrorCalled = false;
        var onSuccessCalled = false;

        await getCtrl(container).runRefundFlow(
          eventId: 'evt1',
          paymentId: 'pay_123',
          paymentAmount: 10000,
          eventStartTime: DateTime.now().add(const Duration(days: 8)),
          paidAt: DateTime.now().subtract(const Duration(hours: 1)),
          showMissingInfo: () async {},
          showNotEligible: () async {},
          confirmRefund: (calc) async => true,
          showError: (msg) async {
            showErrorCalled = true;
            return false; // do not retry
          },
          onSuccess: () async {
            onSuccessCalled = true;
          },
        );

        expect(showErrorCalled, isTrue);
        expect(onSuccessCalled, isFalse);
      },
    );
  });

  // Fix #1951: calculateRefund boundary tests with explicit 'now' control
  group('PurchaseHistoryController.calculateRefund — boundary cases', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWithValue(MockEventRepository()),
        ],
      );
    });

    tearDown(() => container.dispose());

    PurchaseHistoryController ctrl() =>
        container.read(purchaseHistoryControllerProvider.notifier);

    const amount = 10000;
    const grace = 2;
    const cutoff = 7;

    test('grace period: paidAt exactly at boundary (2h ago) → refundable', () {
      final now = DateTime(2026, 1, 15, 12);
      final paidAt = now.subtract(const Duration(hours: grace));
      final eventStart = now.add(const Duration(days: cutoff + 1));

      final result = ctrl().calculateRefund(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: paidAt,
        gracePeriodHours: grace,
        cutoffDays: cutoff,
        now: now,
      );

      expect(result.refundPercentage, equals(100));
    });

    test(
      'grace period: paidAt 1 second past boundary (2h+1s ago) → not refundable (cutoff also missed)',
      () {
        final now = DateTime(2026, 1, 15, 12);
        final paidAt = now.subtract(const Duration(hours: grace, seconds: 1));
        // Event 2 days away — outside 7-day cutoff — no fallback refund
        final eventStart = now.add(const Duration(days: 2));

        final result = ctrl().calculateRefund(
          eventStartTime: eventStart,
          paymentAmount: amount,
          paidAt: paidAt,
          gracePeriodHours: grace,
          cutoffDays: cutoff,
          now: now,
        );

        expect(result.refundPercentage, equals(0));
      },
    );

    test(
      'cutoff: eventStartTime exactly at boundary (7d away) → refundable',
      () {
        final now = DateTime(2026, 1, 15, 12);
        final eventStart = now.add(const Duration(days: cutoff));
        // paidAt far past grace period — only cutoff path applies
        final paidAt = now.subtract(const Duration(days: 1));

        final result = ctrl().calculateRefund(
          eventStartTime: eventStart,
          paymentAmount: amount,
          paidAt: paidAt,
          gracePeriodHours: grace,
          cutoffDays: cutoff,
          now: now,
        );

        expect(result.refundPercentage, equals(100));
      },
    );

    test(
      'cutoff: eventStartTime 1 second before boundary (7d-1s away) → not refundable (grace also missed)',
      () {
        final now = DateTime(2026, 1, 15, 12);
        final eventStart = now
            .add(const Duration(days: cutoff))
            .subtract(const Duration(seconds: 1));
        // paidAt far past grace period
        final paidAt = now.subtract(const Duration(days: 1));

        final result = ctrl().calculateRefund(
          eventStartTime: eventStart,
          paymentAmount: amount,
          paidAt: paidAt,
          gracePeriodHours: grace,
          cutoffDays: cutoff,
          now: now,
        );

        expect(result.refundPercentage, equals(0));
      },
    );

    test('within grace period overrides missed cutoff → refundable', () {
      final now = DateTime(2026, 1, 15, 12);
      // paidAt 30min ago: within 2h grace
      final paidAt = now.subtract(const Duration(minutes: 30));
      // event 2d away: outside 7d cutoff
      final eventStart = now.add(const Duration(days: 2));

      final result = ctrl().calculateRefund(
        eventStartTime: eventStart,
        paymentAmount: amount,
        paidAt: paidAt,
        gracePeriodHours: grace,
        cutoffDays: cutoff,
        now: now,
      );

      expect(result.refundPercentage, equals(100));
    });
  });
}

// Fix #1951: Fake PolicyRepository implementations for runRefundFlow tests

class _ThrowingPolicyRepository implements PolicyRepository {
  const _ThrowingPolicyRepository();

  @override
  Future<Map<String, dynamic>?> getRefundPolicy() async {
    throw Exception('Network error — test fallback scenario');
  }
}

class _StaticPolicyRepository implements PolicyRepository {
  const _StaticPolicyRepository({
    required this.gracePeriodHours,
    required this.cutoffDays,
  });

  final int gracePeriodHours;
  final int cutoffDays;

  @override
  Future<Map<String, dynamic>?> getRefundPolicy() async {
    return {
      'grace_period_hours': gracePeriodHours,
      'cutoff_days': cutoffDays,
    };
  }
}
