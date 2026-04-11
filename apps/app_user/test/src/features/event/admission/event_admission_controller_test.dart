import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockUserRepository mockUserRepo;
  late MockMatchingRepository mockMatchingRepo;
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
      const EntryGroup(
        id: 'group_1',
        eventId: 'event_1',
        gender: 'male',
        birthYearMin: 1990,
        birthYearMax: 2000,
      ),
    ],
  );

  final completedEvent = testEvent.copyWith(status: 'completed');
  final cancelledEvent = testEvent.copyWith(status: 'cancelled');

  final testMatchPair = MatchPair(
    matchId: 'match_1',
    eventId: 'event_1',
    partnerId: 'partner_1',
    matchedAt: DateTime.now(),
  );

  final testEventWithQualification = testEvent.copyWith(
    entryGroups: [
      const EntryGroup(
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
    mockMatchingRepo = MockMatchingRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_1');
    when(() => mockEventRepo.getEventById(any())).thenAnswer(
      (_) async => testEvent,
    );
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

      final state = await container.read(
        eventAdmissionControllerProvider(testEvent).future,
      );
      expect(state.status, EventAdmissionStatus.guest);
    });

    test('State is applied when already applied', () async {
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
          status: 'confirmed',
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
      expect(state.status, EventAdmissionStatus.applied);
    });

    test('State is identityRequired when user is not verified', () async {
      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => null);

      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => const UserProfile(
          id: 'user_1',
          name: 'Test User',
          username: 'test_user',
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
      expect(state.status, EventAdmissionStatus.identityRequired);
    });

    test('State is notEligible when gender does not match', () async {
      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => null);

      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => UserProfile(
          id: 'user_1',
          name: 'Test User',
          username: 'test_user',
          isVerified: true,
          gender: 'female', // Mismatch (Event requires male)
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
      expect(state.status, EventAdmissionStatus.notEligible);
    });

    test(
      'State is qualificationRequired when qualification is missing',
      () async {
        when(
          () => mockEventRepo.getApplication(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => null);

        when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
          (_) async => UserProfile(
            id: 'user_1',
            name: 'Test User',
            username: 'test_user',
            isVerified: true,
            gender: 'male',
            birthDate: DateTime(1995),
          ),
        );
        // Missing 'verif_career'
        when(
          () => mockUserRepo.getApprovedVerificationIds('user_1'),
        ).thenAnswer((_) async => []);
        when(() => mockEventRepo.getEventById(any())).thenAnswer(
          (_) async => testEventWithQualification,
        );

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(
            testEventWithQualification,
          ).future,
        );
        expect(state.status, EventAdmissionStatus.qualificationRequired);
        expect(state.missingVerificationIds, contains('verif_career'));
      },
    );

    test('State is eligible when all conditions match', () async {
      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => null);

      when(() => mockUserRepo.getUserProfile('user_1')).thenAnswer(
        (_) async => UserProfile(
          id: 'user_1',
          name: 'Test User',
          username: 'test_user',
          isVerified: true,
          gender: 'male',
          birthDate: DateTime(1995),
        ),
      );
      when(
        () => mockUserRepo.getApprovedVerificationIds('user_1'),
      ).thenAnswer((_) async => ['verif_career']);
      when(() => mockEventRepo.getEventById(any())).thenAnswer(
        (_) async => testEventWithQualification,
      );

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container.read(
        eventAdmissionControllerProvider(testEventWithQualification).future,
      );
      expect(state.status, EventAdmissionStatus.eligible);
    });

    // Fix #1211: 정원 마감 시 fullOrSoldOut 상태 반환
    test('State is fullOrSoldOut when event is at capacity', () async {
      final fullEvent = testEvent.copyWith(
        maxParticipants: 20,
        currentParticipants: 20,
      );

      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => null);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final state = await container.read(
        eventAdmissionControllerProvider(fullEvent).future,
      );
      expect(state.status, EventAdmissionStatus.fullOrSoldOut);
    });

    test(
      'State is fullOrSoldOut when currentParticipants exceeds max',
      () async {
        final overCapacityEvent = testEvent.copyWith(
          maxParticipants: 10,
          currentParticipants: 11,
        );

        when(
          () => mockEventRepo.getApplication(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => null);

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(overCapacityEvent).future,
        );
        expect(state.status, EventAdmissionStatus.fullOrSoldOut);
      },
    );

    test(
      'existing applicant sees applied status even when event is full',
      () async {
        final fullEvent = testEvent.copyWith(
          maxParticipants: 20,
          currentParticipants: 20,
        );

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
            status: 'confirmed',
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

        // Already-applied users see their status, not fullOrSoldOut
        final state = await container.read(
          eventAdmissionControllerProvider(fullEvent).future,
        );
        expect(state.status, EventAdmissionStatus.applied);
      },
    );
  });

  group('Ended event states', () {
    test(
      'State is eventEnded when event is completed and user is not logged in',
      () async {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
            matchingRepositoryProvider.overrideWith(
              (ref) => mockMatchingRepo,
            ),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(completedEvent).future,
        );
        expect(state.status, EventAdmissionStatus.eventEnded);
      },
    );

    test(
      'State is eventEnded when event is cancelled and user is not logged in',
      () async {
        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
            matchingRepositoryProvider.overrideWith(
              (ref) => mockMatchingRepo,
            ),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(cancelledEvent).future,
        );
        expect(state.status, EventAdmissionStatus.eventEnded);
      },
    );

    test(
      'State is eventEnded when event is completed and user has no application',
      () async {
        when(
          () => mockEventRepo.getApplication(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => null);

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
            matchingRepositoryProvider.overrideWith(
              (ref) => mockMatchingRepo,
            ),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(completedEvent).future,
        );
        expect(state.status, EventAdmissionStatus.eventEnded);
      },
    );

    test(
      'State is eventEnded when event is completed and application was cancelled',
      () async {
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

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
            matchingRepositoryProvider.overrideWith(
              (ref) => mockMatchingRepo,
            ),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(completedEvent).future,
        );
        expect(state.status, EventAdmissionStatus.eventEnded);
      },
    );

    test(
      'State is eventEndedWithResults when completed event has match results',
      () async {
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
            status: 'confirmed',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        when(
          () => mockMatchingRepo.getMyMatches(any()),
        ).thenAnswer((_) async => [testMatchPair]);

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
            matchingRepositoryProvider.overrideWith(
              (ref) => mockMatchingRepo,
            ),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(completedEvent).future,
        );
        expect(state.status, EventAdmissionStatus.eventEndedWithResults);
      },
    );

    test(
      'State is eventEndedParticipated when completed event has no match results',
      () async {
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
            status: 'confirmed',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        when(
          () => mockMatchingRepo.getMyMatches(any()),
        ).thenAnswer((_) async => []);

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
            matchingRepositoryProvider.overrideWith(
              (ref) => mockMatchingRepo,
            ),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(completedEvent).future,
        );
        expect(state.status, EventAdmissionStatus.eventEndedParticipated);
      },
    );

    test(
      'Ended event short-circuits before eligibility — logged-in user without application',
      () async {
        // Even though user is verified and eligible, the ended-event check exits
        // before any eligibility logic runs.
        when(
          () => mockEventRepo.getApplication(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => null);

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
            matchingRepositoryProvider.overrideWith((ref) => mockMatchingRepo),
          ],
        );

        final state = await container.read(
          eventAdmissionControllerProvider(completedEvent).future,
        );
        expect(state.status, EventAdmissionStatus.eventEnded);

        // Verify eligibility-related repos were never called
        verifyNever(() => mockUserRepo.getUserProfile(any()));
        verifyNever(() => mockUserRepo.getApprovedVerificationIds(any()));
      },
    );
  });

  group('Ended event button config', () {
    test('eventEnded shows disabled button', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
          matchingRepositoryProvider.overrideWith(
            (ref) => mockMatchingRepo,
          ),
        ],
      );

      // Wait for the provider to resolve before accessing notifier
      await container.read(
        eventAdmissionControllerProvider(completedEvent).future,
      );
      final controller = container.read(
        eventAdmissionControllerProvider(completedEvent).notifier,
      );
      final config = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.eventEnded),
      );

      expect(config.label, '종료된 이벤트');
      expect(config.enabled, isFalse);
      expect(config.style, AdmissionButtonStyle.disabled);
    });

    test('eventEndedWithResults shows enabled button', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
          matchingRepositoryProvider.overrideWith(
            (ref) => mockMatchingRepo,
          ),
        ],
      );

      await container.read(
        eventAdmissionControllerProvider(completedEvent).future,
      );
      final controller = container.read(
        eventAdmissionControllerProvider(completedEvent).notifier,
      );
      final config = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.eventEndedWithResults),
      );

      expect(config.label, '매칭 결과 보기');
      expect(config.enabled, isTrue);
    });

    test('eventEndedParticipated shows disabled button', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
          matchingRepositoryProvider.overrideWith(
            (ref) => mockMatchingRepo,
          ),
        ],
      );

      await container.read(
        eventAdmissionControllerProvider(completedEvent).future,
      );
      final controller = container.read(
        eventAdmissionControllerProvider(completedEvent).notifier,
      );
      final config = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.eventEndedParticipated),
      );

      expect(config.label, '참여 완료');
      expect(config.enabled, isFalse);
      expect(config.style, AdmissionButtonStyle.disabled);
    });
  });
}
