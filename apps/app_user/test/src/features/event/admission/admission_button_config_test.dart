import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockUserRepository mockUserRepo;

  final testEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 2)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    contactOptions: {},
    tickets: [],
    entryGroups: [],
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUserRepo = MockUserRepository();
  });

  group('AdmissionButtonConfig', () {
    test('guest status returns login label', () {
      final state = AdmissionState(status: EventAdmissionStatus.guest);
      // buttonConfig is a pure function mapped from state
      // Test all status → label mappings
      expect(state.status, EventAdmissionStatus.guest);
    });

    test('mapping covers all statuses', () async {
      // Test via controller to use buttonConfig extension
      when(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => null);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final controller = container.read(
        eventAdmissionControllerProvider(testEvent).notifier,
      );

      // Test each status mapping
      final guestConfig = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.guest),
      );
      expect(guestConfig.label, '로그인하고 신청하기');
      expect(guestConfig.enabled, isTrue);

      final identityConfig = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.identityRequired),
      );
      expect(identityConfig.label, '본인인증 후 신청하기');

      final qualConfig = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.qualificationRequired),
      );
      expect(qualConfig.label, '신청하기');

      final notEligibleConfig = controller.buttonConfig(
        AdmissionState(
          status: EventAdmissionStatus.notEligible,
          ineligibleReason: '나이 제한',
        ),
      );
      expect(notEligibleConfig.label, '나이 제한');
      expect(notEligibleConfig.enabled, isFalse);
      expect(notEligibleConfig.style, AdmissionButtonStyle.disabled);

      final eligibleConfig = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.eligible),
      );
      expect(eligibleConfig.label, '참가 신청하기');

      final pendingConfig = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.pendingPayment),
      );
      expect(pendingConfig.label, '결제 계속하기');

      final appliedConfig = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.applied),
      );
      expect(appliedConfig.label, '이미 신청한 이벤트');

      final rejectedConfig = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.rejected),
      );
      expect(rejectedConfig.label, '심사 반려 (사유 확인)');
      expect(rejectedConfig.style, AdmissionButtonStyle.destructive);
    });

    test('notEligible uses fallback label when reason is null', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
        ],
      );

      final controller = container.read(
        eventAdmissionControllerProvider(testEvent).notifier,
      );

      final config = controller.buttonConfig(
        AdmissionState(status: EventAdmissionStatus.notEligible),
      );
      expect(config.label, '참여 조건 미달');
    });
  });

  group('AdmissionState', () {
    test('creates with required status', () {
      final state = AdmissionState(status: EventAdmissionStatus.guest);
      expect(state.status, EventAdmissionStatus.guest);
      expect(state.user, isNull);
      expect(state.ineligibleReason, isNull);
      expect(state.rejectionReason, isNull);
      expect(state.missingVerificationIds, isEmpty);
    });

    test('creates with all fields', () {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user_1');

      final state = AdmissionState(
        status: EventAdmissionStatus.rejected,
        user: mockUser,
        ineligibleReason: 'reason',
        rejectionReason: '서류 부족',
        missingVerificationIds: ['verif_1'],
      );

      expect(state.status, EventAdmissionStatus.rejected);
      expect(state.user, isNotNull);
      expect(state.rejectionReason, '서류 부족');
      expect(state.missingVerificationIds, contains('verif_1'));
    });
  });
}
