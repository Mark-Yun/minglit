import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

class _FakeIamportControllerCancelled extends IamportController {
  @override
  AsyncValue<IamportResultModel?> build() => const AsyncData(null);

  @override
  Future<String?> startPayment({
    required BuildContext context,
    required String userCode,
    required Map<String, dynamic> data,
  }) async => null;
}

class _FakeIamportControllerCapture extends IamportController {
  Map<String, dynamic>? capturedData;

  @override
  AsyncValue<IamportResultModel?> build() => const AsyncData(null);

  @override
  Future<String?> startPayment({
    required BuildContext context,
    required String userCode,
    required Map<String, dynamic> data,
  }) async {
    capturedData = data;
    return 'imp_uid_test';
  }
}

void main() {
  late MockEventRepository mockEventRepo;
  late MockVerificationRepository mockVerificationRepo;
  late MockUser mockUser;
  late MockBuildContext mockContext;

  final verification = Verification(
    id: 'verification_1',
    category: VerificationCategory.career,
    internalName: 'career',
    displayName: '직장 인증',
    formSchema: const [
      VerificationFormField(type: 'text', label: '회사명', key: 'company'),
    ],
  );

  final verification2 = Verification(
    id: 'verification_2',
    category: VerificationCategory.career,
    internalName: 'school',
    displayName: '학교 인증',
    formSchema: const [
      VerificationFormField(type: 'text', label: '학교명', key: 'school'),
    ],
  );

  final now = DateTime.now();

  // Event with two required verifications per ticket entry group.
  // Used to verify _buildVerificationPayload sends ALL matching verifications.
  late Event multiVerifEvent;

  final testEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    startTime: now,
    endTime: now.add(const Duration(hours: 2)),
    createdAt: now,
    updatedAt: now,
    contactOptions: const {},
    party: Party(
      id: 'party_1',
      partnerId: 'partner_1',
      title: '테스트 파티',
      createdAt: now,
      updatedAt: now,
    ),
    tickets: [
      Ticket(
        id: 'ticket_1',
        eventId: 'event_1',
        name: '일반 티켓',
        createdAt: now,
        updatedAt: now,
        targetEntryGroupIds: const ['group_1'],
        requiredVerificationIds: const [],
        price: 10000,
      ),
      Ticket(
        id: 'ticket_free',
        eventId: 'event_1',
        name: '무료 티켓',
        createdAt: now,
        updatedAt: now,
        targetEntryGroupIds: const ['group_free'],
      ),
    ],
    entryGroups: const [
      EntryGroup(
        id: 'group_1',
        eventId: 'event_1',
        gender: 'male',
        birthYearMin: 1990,
        birthYearMax: 2000,
        requiredVerificationIds: ['verification_1'],
      ),
      EntryGroup(id: 'group_free', eventId: 'event_1'),
    ],
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockVerificationRepo = MockVerificationRepository();
    mockUser = MockUser();
    mockContext = MockBuildContext();

    multiVerifEvent = Event(
      id: 'event_multi',
      partyId: 'party_multi',
      startTime: now,
      endTime: now.add(const Duration(hours: 2)),
      createdAt: now,
      updatedAt: now,
      contactOptions: const {},
      party: Party(
        id: 'party_multi',
        partnerId: 'partner_multi',
        title: '멀티 인증 파티',
        createdAt: now,
        updatedAt: now,
      ),
      tickets: [
        Ticket(
          id: 'ticket_multi',
          eventId: 'event_multi',
          name: '멀티 인증 티켓',
          createdAt: now,
          updatedAt: now,
          targetEntryGroupIds: const ['group_multi'],
          requiredVerificationIds: const [],
          price: 0,
        ),
      ],
      entryGroups: const [
        EntryGroup(
          id: 'group_multi',
          eventId: 'event_multi',
          requiredVerificationIds: ['verification_1', 'verification_2'],
        ),
      ],
    );

    when(() => mockUser.id).thenReturn('user_1');
    when(() => mockUser.userMetadata).thenReturn({'name': 'Test User'});
    when(() => mockUser.phone).thenReturn('01012345678');
    when(() => mockUser.email).thenReturn('test@test.com');
    when(() => mockContext.mounted).thenReturn(true);
    when(
      () => mockEventRepo.getEventById(any()),
    ).thenAnswer((_) async => testEvent);
    when(
      () => mockVerificationRepo.getPartnerRequirementsStatus(
        partnerId: any(named: 'partnerId'),
        requiredVerificationIds: any(named: 'requiredVerificationIds'),
      ),
    ).thenAnswer(
      (_) async => [VerificationRequirementStatus(master: verification)],
    );
  });

  ProviderContainer _createContainer() {
    return createContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => mockUser),
        eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        verificationRepositoryProvider.overrideWith(
          (ref) => mockVerificationRepo,
        ),
      ],
    );
  }

  group('EventApplicationController', () {
    test('initial state starts at identity with new fields', () {
      final container = _createContainer();
      final state = container.read(
        eventApplicationControllerProvider(testEvent),
      );

      expect(state.step, EventApplicationStep.identity);
      expect(state.identityCompleted, isFalse);
      expect(state.partnerVerifications, isEmpty);
      expect(state.consentGranted, isFalse);
      expect(state.verificationData, isEmpty);
    });

    test('loads partner verifications when ticket is selected', () async {
      final container = _createContainer();
      final notifier = container.read(
        eventApplicationControllerProvider(testEvent).notifier,
      );

      await notifier.selectTicket(testEvent.tickets!.first);
      final state = container.read(
        eventApplicationControllerProvider(testEvent),
      );

      expect(state.selectedTicket?.id, 'ticket_1');
      expect(state.partnerVerifications, hasLength(1));
      expect(
        state.partnerVerifications.first.verification.id,
        'verification_1',
      );
    });

    test(
      'identity -> verification -> consent -> payment transitions work',
      () async {
        final container = _createContainer();
        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        await notifier.selectTicket(testEvent.tickets!.first);
        notifier.markIdentityCompleted();
        await notifier.nextStep(mockContext);
        expect(
          container.read(eventApplicationControllerProvider(testEvent)).step,
          EventApplicationStep.partnerVerification,
        );

        notifier.updateVerificationData('verification_1', 'company', 'Minglit');
        await notifier.nextStep(mockContext);
        expect(
          container.read(eventApplicationControllerProvider(testEvent)).step,
          EventApplicationStep.consent,
        );

        notifier.setConsentGranted(true);
        await notifier.nextStep(mockContext);
        expect(
          container.read(eventApplicationControllerProvider(testEvent)).step,
          EventApplicationStep.payment,
        );
      },
    );

    test(
      'skips partner verification when all requirements are approved',
      () async {
        when(
          () => mockVerificationRepo.getPartnerRequirementsStatus(
            partnerId: any(named: 'partnerId'),
            requiredVerificationIds: any(named: 'requiredVerificationIds'),
          ),
        ).thenAnswer(
          (_) async => [
            VerificationRequirementStatus(
              master: verification,
              verifiedResult: const {'verification_id': 'verification_1'},
            ),
          ],
        );

        final container = _createContainer();
        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );

        await notifier.selectTicket(testEvent.tickets!.first);
        notifier.markIdentityCompleted();
        await notifier.nextStep(mockContext);

        expect(
          container.read(eventApplicationControllerProvider(testEvent)).step,
          EventApplicationStep.consent,
        );
      },
    );

    test('submitApplication succeeds for free ticket', () async {
      when(
        () => mockEventRepo.applyEvent(
          eventId: any(named: 'eventId'),
          ticketId: any(named: 'ticketId'),
          verificationData: any(named: 'verificationData'),
        ),
      ).thenAnswer(
        (_) async => const FreeApplyEventResult(applicationId: 'app_123'),
      );

      final container = _createContainer();
      final notifier = container.read(
        eventApplicationControllerProvider(testEvent).notifier,
      );

      await notifier.selectTicket(testEvent.tickets!.last);
      notifier.markIdentityCompleted();
      notifier.setConsentGranted(true);
      await notifier.submitApplication(mockContext);

      expect(
        container.read(eventApplicationControllerProvider(testEvent)).status,
        EventApplicationStatus.success,
      );
    });

    test('resetStatus preserves current step and data', () async {
      when(
        () => mockEventRepo.applyEvent(
          eventId: any(named: 'eventId'),
          ticketId: any(named: 'ticketId'),
          verificationData: any(named: 'verificationData'),
        ),
      ).thenThrow(const MinglitUserException('실패'));

      final container = _createContainer();
      final notifier = container.read(
        eventApplicationControllerProvider(testEvent).notifier,
      );

      await notifier.selectTicket(testEvent.tickets!.last);
      notifier.markIdentityCompleted();
      notifier.setConsentGranted(true);
      await notifier.nextStep(mockContext);
      await notifier.nextStep(mockContext);
      await notifier.submitApplication(mockContext);
      notifier.resetStatus();

      final state = container.read(
        eventApplicationControllerProvider(testEvent),
      );
      expect(state.status, EventApplicationStatus.initial);
      expect(state.step, EventApplicationStep.payment);
      expect(state.selectedTicket?.id, 'ticket_free');
    });

    // Regression test for Fix #1924: buyer_tel must not use fake phone numbers.
    // Iamport records buyer_tel in PG records; a fake number corrupts prod data.
    test(
      'buyer_tel is empty string when user phone is null (Fix #1924)',
      () async {
        final captureController = _FakeIamportControllerCapture();
        when(() => mockUser.phone).thenReturn(null);
        when(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            verificationData: any(named: 'verificationData'),
          ),
        ).thenAnswer(
          (_) async => const PaidApplyEventResult(
            applicationId: 'app_paid',
            orderId: 'order_1',
            paymentAmount: 10000,
          ),
        );
        when(
          () => mockEventRepo.confirmPayment(
            impUid: any(named: 'impUid'),
            merchantUid: any(named: 'merchantUid'),
          ),
        ).thenAnswer((_) async {});

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
            verificationRepositoryProvider.overrideWith(
              (ref) => mockVerificationRepo,
            ),
            iamportControllerProvider.overrideWith(() => captureController),
            iamportConfigProvider.overrideWithValue(
              const IamportConfig(userCode: 'imp_test'),
            ),
          ],
        );

        final notifier = container.read(
          eventApplicationControllerProvider(testEvent).notifier,
        );
        await notifier.selectTicket(testEvent.tickets!.first);
        notifier.markIdentityCompleted();
        notifier.setConsentGranted(true);
        await notifier.submitApplication(mockContext);

        expect(captureController.capturedData?['buyer_tel'], '');
      },
    );

    // Regression: Fix #2234 — _buildVerificationPayload previously used firstWhere,
    // sending only the first matching verification and losing the rest.
    test(
      'all matching verifications are included in applyEvent payload',
      () async {
        Map<String, dynamic>? capturedVerifData;
        when(
          () => mockVerificationRepo.getPartnerRequirementsStatus(
            partnerId: any(named: 'partnerId'),
            requiredVerificationIds: any(named: 'requiredVerificationIds'),
          ),
        ).thenAnswer(
          (_) async => [
            VerificationRequirementStatus(master: verification),
            VerificationRequirementStatus(master: verification2),
          ],
        );
        when(
          () => mockEventRepo.getEventById(any()),
        ).thenAnswer((_) async => multiVerifEvent);
        when(
          () => mockEventRepo.applyEvent(
            eventId: any(named: 'eventId'),
            ticketId: any(named: 'ticketId'),
            verificationData: any(named: 'verificationData'),
          ),
        ).thenAnswer((invocation) async {
          capturedVerifData = invocation.namedArguments[
              const Symbol('verificationData')] as Map<String, dynamic>?;
          return const FreeApplyEventResult(applicationId: 'app_multi');
        });

        final container = _createContainer();
        final notifier = container.read(
          eventApplicationControllerProvider(multiVerifEvent).notifier,
        );

        await notifier.selectTicket(multiVerifEvent.tickets!.first);
        notifier.updateVerificationData('verification_1', 'company', 'Minglit');
        notifier.updateVerificationData('verification_2', 'school', 'KAIST');
        notifier.markIdentityCompleted();
        notifier.setConsentGranted(true);
        await notifier.submitApplication(mockContext);

        // Both verifications must be in the payload — not just the first one
        expect(capturedVerifData, isNotNull);
        final verifs =
            capturedVerifData!['verifications'] as List<Map<String, dynamic>>;
        expect(verifs, hasLength(2));
        expect(
          verifs.map((v) => v['verification_id']),
          containsAll(['verification_1', 'verification_2']),
        );
      },
    );

    test('payment cancellation sets error status', () async {
      when(
        () => mockEventRepo.applyEvent(
          eventId: any(named: 'eventId'),
          ticketId: any(named: 'ticketId'),
          verificationData: any(named: 'verificationData'),
        ),
      ).thenAnswer(
        (_) async => const PaidApplyEventResult(
          applicationId: 'app_paid',
          orderId: 'order_1',
          paymentAmount: 10000,
        ),
      );

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          verificationRepositoryProvider.overrideWith(
            (ref) => mockVerificationRepo,
          ),
          iamportControllerProvider.overrideWith(
            () => _FakeIamportControllerCancelled(),
          ),
          iamportConfigProvider.overrideWithValue(
            const IamportConfig(userCode: 'imp_test'),
          ),
        ],
      );

      final notifier = container.read(
        eventApplicationControllerProvider(testEvent).notifier,
      );
      await notifier.selectTicket(testEvent.tickets!.first);
      notifier.markIdentityCompleted();
      notifier.setConsentGranted(true);
      await notifier.submitApplication(mockContext);

      final state = container.read(
        eventApplicationControllerProvider(testEvent),
      );
      expect(state.status, EventApplicationStatus.error);
      expect(state.errorMessage, '결제가 취소되었습니다.');
    });
  });
}
