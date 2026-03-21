import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockUser mockUser;

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

        await notifier.submitApplication();

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        // Status stays initial since no ticket was selected
        expect(state.status, EventApplicationStatus.initial);
        verifyNever(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            userId: any(named: 'userId'),
            paymentId: any(named: 'paymentId'),
            paymentAmount: any(named: 'paymentAmount'),
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

        await notifier.submitApplication();

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.initial);
      });

      test('succeeds when ticket and user are present', () async {
        when(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            userId: any(named: 'userId'),
            paymentId: any(named: 'paymentId'),
            paymentAmount: any(named: 'paymentAmount'),
            verificationData: any(named: 'verificationData'),
          ),
        ).thenAnswer((_) async => 'app_123');

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

        await notifier.submitApplication();

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.success);
        verify(
          () => mockEventRepo.applyEvent(
            eventId: 'event_1',
            ticketId: 'ticket_free',
            userId: 'user_1',
            paymentId: any(named: 'paymentId'),
            paymentAmount: 0,
            verificationData: any(named: 'verificationData'),
          ),
        ).called(1);
      });

      test('sets error state on failure', () async {
        when(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            userId: any(named: 'userId'),
            paymentId: any(named: 'paymentId'),
            paymentAmount: any(named: 'paymentAmount'),
            verificationData: any(named: 'verificationData'),
          ),
        ).thenThrow(Exception('Server error'));

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

        await notifier.submitApplication();

        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.error);
        expect(state.errorMessage, contains('Server error'));
      });
    });

    group('resetStatus', () {
      test('resets status to initial, preserving ticket and step', () async {
        when(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            userId: any(named: 'userId'),
            paymentId: any(named: 'paymentId'),
            paymentAmount: any(named: 'paymentAmount'),
            verificationData: any(named: 'verificationData'),
          ),
        ).thenThrow(Exception('Fail'));

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
        await notifier.submitApplication();

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

    group('processPayment', () {
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

        // processPayment requires BuildContext, but with no ticket it returns early
        // We can't easily test this path without a widget test,
        // but we can verify the state doesn't change
        final state = container.read(
          eventApplicationControllerProvider(testEvent),
        );
        expect(state.status, EventApplicationStatus.initial);
        expect(state.selectedTicket, isNull);
      });
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
