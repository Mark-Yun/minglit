import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockUserRepository mockUserRepo;
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
        name: 'Normal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetEntryGroupIds: [],
        requiredVerificationIds: [],
        price: 10000,
      ),
    ],
    entryGroups: [],
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUserRepo = MockUserRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_1');
  });

  group('EventAdmissionController - edge cases', () {
    test('pendingPayment when application status is pending', () async {
      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => EventApplication(
          id: 'app_1',
          eventId: 'event_1',
          ticketId: 'ticket_1',
          userId: 'user_1',
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container.read(
        eventAdmissionControllerProvider(testEvent).future,
      );
      expect(state.status, EventAdmissionStatus.pendingPayment);
    });

    test('rejected when application status is rejected', () async {
      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => EventApplication(
          id: 'app_1',
          eventId: 'event_1',
          ticketId: 'ticket_1',
          userId: 'user_1',
          status: 'rejected',
          rejectionReason: '서류 부족',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container.read(
        eventAdmissionControllerProvider(testEvent).future,
      );
      expect(state.status, EventAdmissionStatus.rejected);
      expect(state.rejectionReason, '서류 부족');
    });

    test('eligible when no entry groups and no tickets', () async {
      final noTicketEvent = testEvent.copyWith(tickets: []);
      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => null);
      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => UserProfile(
          id: 'user_1',
          name: 'Test',
          username: 'test',
          isVerified: true,
          gender: 'male',
          birthDate: DateTime(1995),
        ),
      );
      when(
        () => mockUserRepo.getApprovedVerificationIds('user_1'),
      ).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container.read(
        eventAdmissionControllerProvider(noTicketEvent).future,
      );
      expect(state.status, EventAdmissionStatus.eligible);
    });

    test('cancelled application treated as no application', () async {
      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => EventApplication(
          id: 'app_1',
          eventId: 'event_1',
          ticketId: 'ticket_1',
          userId: 'user_1',
          status: 'cancelled',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => UserProfile(
          id: 'user_1',
          name: 'Test',
          username: 'test',
          isVerified: true,
          gender: 'male',
          birthDate: DateTime(1995),
        ),
      );
      when(
        () => mockUserRepo.getApprovedVerificationIds('user_1'),
      ).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container.read(
        eventAdmissionControllerProvider(testEvent).future,
      );
      // Cancelled application should fall through to eligibility check
      expect(state.status, EventAdmissionStatus.eligible);
    });
  });
}
