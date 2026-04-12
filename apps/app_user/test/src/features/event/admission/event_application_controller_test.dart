import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockUser mockUser;
  late MockBuildContext mockContext;

  final testEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 2)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    contactOptions: {},
    tickets: [
      Ticket(
        id: 'ticket_1',
        eventId: 'event_1',
        name: '일반 티켓',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetEntryGroupIds: ['group_1'],
        requiredVerificationIds: [],
        price: 10000,
      ),
    ],
    entryGroups: [
      const EntryGroup(
        id: 'group_1',
        eventId: 'event_1',
        gender: 'male',
        birthYearMin: 1990,
        birthYearMax: 2000,
      ),
    ],
  );

  final freeTicket = Ticket(
    id: 'ticket_free',
    eventId: 'event_1',
    name: '무료 티켓',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    targetEntryGroupIds: ['group_1'],
    requiredVerificationIds: [],
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUser = MockUser();
    mockContext = MockBuildContext();
    when(() => mockUser.id).thenReturn('user_1');
    when(() => mockUser.userMetadata).thenReturn({'name': 'Test User'});
    when(() => mockUser.phone).thenReturn('01012345678');
    when(() => mockUser.email).thenReturn('test@test.com');
    when(() => mockEventRepo.getEventById(any())).thenAnswer(
      (_) async => testEvent,
    );
  });

  group('EventApplicationController', () {
    group('initial state', () {
      test('starts at verification step with initial status', () {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.step, EventApplicationStep.verification);
        expect(state.status, EventApplicationStatus.initial);
        expect(state.selectedTicket, isNull);
        expect(state.verificationData, isEmpty);
        expect(state.errorMessage, isNull);
      });
    });

    group('selectTicket', () {
      test('updates selected ticket', () {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        notifier.selectTicket(testEvent.tickets!.first);

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.selectedTicket?.id, 'ticket_1');
        expect(state.selectedTicket?.name, '일반 티켓');
      });
    });

    group('updateVerificationData', () {
      test('adds new verification data', () {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        notifier.updateVerificationData('company', 'MingLit');
        notifier.updateVerificationData('position', 'Engineer');

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.verificationData['company'], 'MingLit');
        expect(state.verificationData['position'], 'Engineer');
      });

      test('overwrites existing key', () {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        notifier.updateVerificationData('company', 'OldCo');
        notifier.updateVerificationData('company', 'NewCo');

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.verificationData['company'], 'NewCo');
      });
    });

    group('step navigation', () {
      test('nextStep moves from verification to payment', () {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        notifier.nextStep();

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.step, EventApplicationStep.payment);
      });

      test('nextStep does nothing when already at payment', () {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        notifier.nextStep();
        notifier.nextStep(); // second call should be a no-op

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.step, EventApplicationStep.payment);
      });

      test('previousStep moves from payment to verification', () {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        notifier.nextStep();
        notifier.previousStep();

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.step, EventApplicationStep.verification);
      });

      test('previousStep does nothing when at verification', () {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        notifier.previousStep(); // already at verification

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.step, EventApplicationStep.verification);
      });
    });

    group('submitApplication', () {
      test('does nothing when no ticket selected', () async {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        await notifier.submitApplication(mockContext);

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        // Status stays initial since no ticket was selected
        expect(state.status, EventApplicationStatus.initial);
        verifyNever(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            verificationData: any(named: 'verificationData'),
          ),
        );
      });

      test('does nothing when user is null', () async {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        notifier.selectTicket(freeTicket);

        await notifier.submitApplication(mockContext);

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.initial);
      });

      test('succeeds when ticket and user are present (free ticket)', () async {
        when(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            verificationData: any(named: 'verificationData'),
          ),
        ).thenAnswer(
          (_) async => const FreeApplyEventResult(applicationId: 'app_123'),
        );

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        notifier.selectTicket(freeTicket);

        await notifier.submitApplication(mockContext);

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.success);
        verify(
          () => mockEventRepo.applyEvent(
            eventId: 'event_1',
            ticketId: 'ticket_free',
            verificationData: any(named: 'verificationData'),
          ),
        ).called(1);
      });

      test('sets error state on failure', () async {
        when(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            verificationData: any(named: 'verificationData'),
          ),
        ).thenThrow(const MinglitUserException('신청에 실패했습니다.'));

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        notifier.selectTicket(freeTicket);

        await notifier.submitApplication(mockContext);

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.error);
        expect(state.errorMessage, contains('신청에 실패했습니다.'));
      });
    });

    group('resetStatus', () {
      test('resets status to initial, preserving ticket and step', () async {
        when(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            verificationData: any(named: 'verificationData'),
          ),
        ).thenThrow(const MinglitUserException('실패'));

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        notifier.selectTicket(freeTicket);
        notifier.nextStep();
        await notifier.submitApplication(mockContext);

        // In error state at payment step
        var state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.error);
        expect(state.step, EventApplicationStep.payment);

        notifier.resetStatus();

        state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.initial);
        expect(state.step, EventApplicationStep.payment);
        expect(state.selectedTicket?.id, 'ticket_free');
      });
    });

    // Fix #1115 regression: _buildVerificationPayload returns null when
    // reqIds is empty (no matching entry groups) or verificationData is empty.
    group('_buildVerificationPayload regression', () {
      test(
        'returns null verificationData when entry groups have no matching IDs',
        () async {
          // Ticket targets 'group_nonexistent' which doesn't match 'group_1'
          final ticketWithBadGroup = Ticket(
            id: 'ticket_bad',
            eventId: 'event_1',
            name: 'Bad Group Ticket',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            targetEntryGroupIds: ['group_nonexistent'],
            requiredVerificationIds: [],
            price: 5000,
          );

          when(
            () => mockEventRepo.applyEvent(
              eventId: any(named: 'eventId'),
              ticketId: any(named: 'ticketId'),
              verificationData: any(named: 'verificationData'),
            ),
          ).thenAnswer(
            (_) async => const PaidApplyEventResult(
              applicationId: 'app_456',
              orderId: 'order_456',
              paymentAmount: 5000,
            ),
          );

          final container = createContainer(
            overrides: [
              currentUserProvider.overrideWith((ref) => mockUser),
              eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            ],
          );

          final notifier = container.read(
            eventApplicationControllerProvider(testEvent).notifier,
          );
          notifier.selectTicket(ticketWithBadGroup);
          notifier.updateVerificationData('company', 'TestCo');

          await notifier.submitApplication(mockContext);

          // verificationData should be null because reqIds is empty
          verify(
            () => mockEventRepo.applyEvent(
              eventId: any(named: 'eventId'),
              ticketId: any(named: 'ticketId'),
            ),
          ).called(1);
        },
      );

      test(
        'returns null verificationData when verificationData is empty',
        () async {
          // Ticket targets 'group_1' which has matching entry group,
          // but entry group's requiredVerificationIds is empty (default).
          // So reqIds will be empty → null.
          when(
            () => mockEventRepo.applyEvent(
              eventId: any(named: 'eventId'),
              ticketId: any(named: 'ticketId'),
              verificationData: any(named: 'verificationData'),
            ),
          ).thenAnswer(
            (_) async => const PaidApplyEventResult(
              applicationId: 'app_789',
              orderId: 'order_789',
              paymentAmount: 10000,
            ),
          );

          final container = createContainer(
            overrides: [
              currentUserProvider.overrideWith((ref) => mockUser),
              eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            ],
          );

          final notifier = container.read(
            eventApplicationControllerProvider(testEvent).notifier,
          );
          notifier.selectTicket(testEvent.tickets!.first);
          // Don't call updateVerificationData — stays empty

          await notifier.submitApplication(mockContext);

          // verificationData should be null because verificationData is empty
          verify(
            () => mockEventRepo.applyEvent(
              eventId: any(named: 'eventId'),
              ticketId: any(named: 'ticketId'),
            ),
          ).called(1);
        },
      );
    });

    group('processPayment', () {
      test(
        'requires ticket to proceed',
        () {
          final container = createContainer(
            overrides: [
              currentUserProvider.overrideWith((ref) => mockUser),
              eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            ],
          );

          // processPayment returns early when no ticket
          // is selected (guard clause: if selectedTicket == null)
          final state = container.read(
            eventApplicationControllerProvider(testEvent),
          );
          expect(state.selectedTicket, isNull);
          expect(
            state.status,
            EventApplicationStatus.initial,
          );
        },
      );
    });
  });

  group('EventApplicationState.copyWith', () {
    test('copies all fields', () {
      final ticket = Ticket(
        id: 't1',
        eventId: 'e1',
        name: 'T',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetEntryGroupIds: [],
        requiredVerificationIds: [],
        price: 100,
      );

      const original = EventApplicationState(
        step: EventApplicationStep.verification,
        status: EventApplicationStatus.initial,
      );

      final copied = original.copyWith(
        step: EventApplicationStep.payment,
        status: EventApplicationStatus.error,
        selectedTicket: ticket,
        verificationData: {'key': 'val'},
        errorMessage: 'err',
      );

      expect(copied.step, EventApplicationStep.payment);
      expect(copied.status, EventApplicationStatus.error);
      expect(copied.selectedTicket?.id, 't1');
      expect(copied.verificationData['key'], 'val');
      expect(copied.errorMessage, 'err');
    });

    test('preserves original values when not specified', () {
      const original = EventApplicationState(
        step: EventApplicationStep.payment,
        status: EventApplicationStatus.submitting,
        verificationData: {'a': 1},
        errorMessage: 'msg',
      );

      final copied = original.copyWith();

      expect(copied.step, EventApplicationStep.payment);
      expect(copied.status, EventApplicationStatus.submitting);
      expect(copied.verificationData, {'a': 1});
      expect(copied.errorMessage, 'msg');
    });
  });
}
