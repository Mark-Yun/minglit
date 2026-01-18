import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/data/repositories/user_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockUserRepository mockUserRepo;
  late MockUser mockUser;

  // --- Test Data ---
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
        name: 'Normal Ticket',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetEntryGroupIds: ['group_1'],
        requiredVerificationIds: [],
        price: 10000,
      ),
    ],
    entryGroups: [
      EntryGroup(
        id: 'group_1',
        eventId: 'event_1',
        gender: 'male',
        birthYearMin: 1990,
        birthYearMax: 2000,
        requiredVerificationIds: [],
      ),
    ],
  );

  final testEventWithQualification = testEvent.copyWith(
    entryGroups: [
      EntryGroup(
        id: 'group_1',
        eventId: 'event_1',
        gender: 'male',
        birthYearMin: 1990,
        birthYearMax: 2000,
        requiredVerificationIds: ['verif_career'],
      ),
    ],
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUserRepo = MockUserRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_1');
  });

  group('EventAdmissionController', () {
    test('State is guest when user is not logged in', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container
          .read(eventAdmissionControllerProvider(testEvent).future);
      expect(state.status, EventAdmissionStatus.guest);
    });

    test('State is applied when already applied', () async {
      when(() => mockEventRepo.checkApplicationStatus(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => true);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container
          .read(eventAdmissionControllerProvider(testEvent).future);
      expect(state.status, EventAdmissionStatus.applied);
    });

    test('State is identityRequired when user is not verified', () async {
      when(() => mockEventRepo.checkApplicationStatus(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => false);

      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => const UserProfile(
          id: 'user_1',
          name: 'Test User',
          username: 'test_user',
          isVerified: false, // Not Verified
        ),
      );

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container
          .read(eventAdmissionControllerProvider(testEvent).future);
      expect(state.status, EventAdmissionStatus.identityRequired);
    });

    test('State is notEligible when gender does not match', () async {
      when(() => mockEventRepo.checkApplicationStatus(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => false);

      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => UserProfile(
          id: 'user_1',
          name: 'Test User',
          username: 'test_user',
          isVerified: true,
          gender: 'female', // Mismatch (Event requires male)
          birthDate: DateTime(1995, 1, 1),
        ),
      );
      when(() => mockUserRepo.getApprovedVerificationIds('user_1'))
          .thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container
          .read(eventAdmissionControllerProvider(testEvent).future);
      expect(state.status, EventAdmissionStatus.notEligible);
    });

    test('State is qualificationRequired when qualification is missing',
        () async {
      when(() => mockEventRepo.checkApplicationStatus(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => false);

      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => UserProfile(
          id: 'user_1',
          name: 'Test User',
          username: 'test_user',
          isVerified: true,
          gender: 'male',
          birthDate: DateTime(1995, 1, 1),
        ),
      );
      // Missing 'verif_career'
      when(() => mockUserRepo.getApprovedVerificationIds('user_1'))
          .thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container
          .read(eventAdmissionControllerProvider(testEventWithQualification).future);
      expect(state.status, EventAdmissionStatus.qualificationRequired);
      expect(state.missingVerificationIds, contains('verif_career'));
    });

    test('State is eligible when all conditions match', () async {
      when(() => mockEventRepo.checkApplicationStatus(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => false);

      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => UserProfile(
          id: 'user_1',
          name: 'Test User',
          username: 'test_user',
          isVerified: true,
          gender: 'male',
          birthDate: DateTime(1995, 1, 1),
        ),
      );
      when(() => mockUserRepo.getApprovedVerificationIds('user_1'))
          .thenAnswer((_) async => ['verif_career']);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container
          .read(eventAdmissionControllerProvider(testEventWithQualification).future);
      expect(state.status, EventAdmissionStatus.eligible);
    });
  });
}