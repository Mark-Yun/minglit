import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockUser mockUser;

  final now = DateTime.now();

  final testTicketPaid = Ticket(
    id: 'ticket_paid',
    eventId: 'event_1',
    name: '유료 티켓',
    createdAt: now,
    updatedAt: now,
    targetEntryGroupIds: [],
    requiredVerificationIds: [],
    price: 15000,
  );

  final testTicketFree = Ticket(
    id: 'ticket_free',
    eventId: 'event_1',
    name: '무료 티켓',
    createdAt: now,
    updatedAt: now,
    targetEntryGroupIds: [],
    requiredVerificationIds: [],
  );

  final testEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    contactOptions: {},
    tickets: [testTicketPaid, testTicketFree],
    entryGroups: [],
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_1');
  });

  group('EventApplicationController', () {
    group('selectTicket', () {
      test('updates selectedTicket in state', () {
        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        controller.selectTicket(testTicketPaid);

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.selectedTicket?.id, 'ticket_paid');
      });
    });

    group('processPayment — free ticket (requires_payment=false)', () {
      test('succeeds without launching iamport', () async {
        when(
          () => mockEventRepo.createOrder(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
          ),
        ).thenAnswer(
          (_) async => const CreateOrderResult(
            applicationId: 'app-free',
            amount: 0,
            requiresPayment: false,
            ticketName: '무료 티켓',
          ),
        );

        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        controller.selectTicket(testTicketFree);

        // processPayment with a dummy BuildContext — for free tickets
        // no payment widget is launched so no real context needed
        await controller.processPayment(
          _FakeBuildContext(),
        );

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.success);
        // createOrder was called with the free ticket
        verify(
          () => mockEventRepo.createOrder(
            eventId: 'event_1',
            ticketId: 'ticket_free',
          ),
        ).called(1);
      });
    });

    group('processPayment — error handling', () {
      test('sets error status on MinglitUserException', () async {
        when(
          () => mockEventRepo.createOrder(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
          ),
        ).thenThrow(const MinglitUserException('티켓이 매진되었습니다.'));

        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        controller.selectTicket(testTicketPaid);

        await controller.processPayment(_FakeBuildContext());

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.error);
        expect(state.errorMessage, isNotNull);
      });

      test('sets error status on TICKET_SOLD_OUT', () async {
        when(
          () => mockEventRepo.createOrder(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
          ),
        ).thenThrow(const MinglitUserException('티켓이 매진되었습니다.'));

        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        controller.selectTicket(testTicketPaid);

        await controller.processPayment(_FakeBuildContext());

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.error);
        expect(state.errorMessage, contains('매진'));
      });

      test('sets error status on ALREADY_APPLIED', () async {
        when(
          () => mockEventRepo.createOrder(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
          ),
        ).thenThrow(const MinglitUserException('이미 신청한 이벤트입니다.'));

        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        controller.selectTicket(testTicketPaid);

        await controller.processPayment(_FakeBuildContext());

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.error);
        expect(state.errorMessage, contains('이미 신청'));
      });
    });

    group('processPayment — no ticket selected', () {
      test('does nothing when no ticket selected', () async {
        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        // Do NOT call selectTicket
        await controller.processPayment(_FakeBuildContext());

        // Should remain in initial state
        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.initial);
        verifyNever(
          () => mockEventRepo.createOrder(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
          ),
        );
      });
    });

    group('processPayment — user not logged in', () {
      test('does nothing when user is null', () async {
        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => null),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        controller.selectTicket(testTicketPaid);

        await controller.processPayment(_FakeBuildContext());

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.initial);
        verifyNever(
          () => mockEventRepo.createOrder(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
          ),
        );
      });
    });

    group('submitApplication', () {
      test('delegates to processPayment', () async {
        when(
          () => mockEventRepo.createOrder(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
          ),
        ).thenAnswer(
          (_) async => const CreateOrderResult(
            applicationId: 'app-free-2',
            amount: 0,
            requiresPayment: false,
            ticketName: '무료 티켓',
          ),
        );

        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        controller.selectTicket(testTicketFree);

        await controller.submitApplication(_FakeBuildContext());

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.success);
      });
    });

    group('resetStatus', () {
      test('resets status to initial while preserving other state', () async {
        when(
          () => mockEventRepo.createOrder(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
          ),
        ).thenThrow(const MinglitUserException('오류'));

        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
        );
        final controller = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        controller.selectTicket(testTicketPaid);
        await controller.processPayment(_FakeBuildContext());

        // Confirm we're in error state
        expect(
          container.read(eventApplicationControllerProvider(testEvent)).status,
          EventApplicationStatus.error,
        );

        controller.resetStatus();

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.initial);
        expect(state.selectedTicket?.id, 'ticket_paid'); // preserved
        expect(state.errorMessage, isNull);
      });
    });
  });
}

/// Minimal fake BuildContext for tests that don't need widget rendering.
class _FakeBuildContext extends Fake implements BuildContext {}
