import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

void main() {
  group('PartnerApplyController', () {
    late MockPartnerRepository mockRepo;

    setUpAll(() {
      registerFallbackValue(const PartnerApplication(id: '', userId: ''));
    });

    setUp(() {
      mockRepo = MockPartnerRepository();
      when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
      when(() => mockRepo.saveDraft(any())).thenAnswer(
        (_) async => const PartnerApplication(id: 'draft_id', userId: 'user_1'),
      );
    });

    ProviderContainer buildContainer() {
      return createContainer(
        overrides: [
          partnerRepositoryProvider.overrideWith((ref) => mockRepo),
        ],
      );
    }

    test('1. initial state has currentStep=0 and all string fields empty', () {
      final container = buildContainer();
      final state = container.read(partnerApplyControllerProvider);

      expect(state.currentStep, 0);
      expect(state.brandName, '');
      expect(state.introduction, '');
      expect(state.bizName, '');
      expect(state.bizNumber, '');
      expect(state.representativeName, '');
      expect(state.contactPhone, '');
      expect(state.contactEmail, '');
      expect(state.address, '');
      expect(state.bankName, '');
      expect(state.accountNumber, '');
      expect(state.accountHolder, '');
      expect(state.taxEmail, '');
    });

    test('2. updateField brandName updates state.brandName', () {
      final container = buildContainer();
      container
          .read(partnerApplyControllerProvider.notifier)
          .updateField('brandName', 'Test Brand');

      expect(
        container.read(partnerApplyControllerProvider).brandName,
        'Test Brand',
      );
    });

    test('3. validateStep(0) returns false when brandName is empty', () {
      final container = buildContainer();
      // brand name is empty by default
      expect(
        container.read(partnerApplyControllerProvider.notifier).validateStep(0),
        isFalse,
      );
    });

    test('4. validateStep(0) returns true when brandName is non-empty', () {
      final container = buildContainer();
      container
          .read(partnerApplyControllerProvider.notifier)
          .updateField('brandName', 'My Café');

      expect(
        container.read(partnerApplyControllerProvider.notifier).validateStep(0),
        isTrue,
      );
    });

    test('5. previousStep when currentStep==0 stays at 0', () {
      final container = buildContainer();
      container.read(partnerApplyControllerProvider.notifier).previousStep();

      expect(
        container.read(partnerApplyControllerProvider).currentStep,
        0,
      );
    });

    test('6. setStep(2) sets currentStep to 2', () {
      final container = buildContainer();
      container.read(partnerApplyControllerProvider.notifier).setStep(2);

      expect(
        container.read(partnerApplyControllerProvider).currentStep,
        2,
      );
    });

    test('setStep out of range does not change currentStep', () {
      final container = buildContainer();
      container
          .read(partnerApplyControllerProvider.notifier)
          .setStep(10); // totalSteps = 5, so 10 is invalid

      expect(
        container.read(partnerApplyControllerProvider).currentStep,
        0,
      );
    });

    test('canProceed returns false when required fields are empty', () {
      final container = buildContainer();
      expect(
        container.read(partnerApplyControllerProvider.notifier).canProceed(),
        isFalse,
      );
    });

    test(
      'canProceed returns true after filling required fields for step 0',
      () {
        final container = buildContainer();
        container
            .read(partnerApplyControllerProvider.notifier)
            .updateField('brandName', 'Brand X');

        expect(
          container.read(partnerApplyControllerProvider.notifier).canProceed(),
          isTrue,
        );
      },
    );

    test('multiple updateField calls update each field independently', () {
      final container = buildContainer();
      container.read(partnerApplyControllerProvider.notifier)
        ..updateField('brandName', 'Brand A')
        ..updateField('introduction', 'Hello world')
        ..updateField('contactEmail', 'test@test.com');

      final state = container.read(partnerApplyControllerProvider);
      expect(state.brandName, 'Brand A');
      expect(state.introduction, 'Hello world');
      expect(state.contactEmail, 'test@test.com');
    });

    test('nextStep() increments currentStep and calls saveDraft', () async {
      final container = buildContainer();
      final notifier = container.read(partnerApplyControllerProvider.notifier);
      expect(
        container.read(partnerApplyControllerProvider).currentStep,
        0,
      );

      await notifier.nextStep();

      expect(
        container.read(partnerApplyControllerProvider).currentStep,
        1,
      );
      verify(() => mockRepo.saveDraft(any())).called(1);
    });

    test('previousStep() decrements currentStep', () {
      final container = buildContainer();
      container.read(partnerApplyControllerProvider.notifier)
        ..setStep(2)
        ..previousStep();

      expect(
        container.read(partnerApplyControllerProvider).currentStep,
        1,
      );
    });

    test('nextStep() at last step stays at last step', () async {
      final container = buildContainer();
      final notifier = container.read(partnerApplyControllerProvider.notifier);
      // Set to last step before testing nextStep boundary
      container.read(partnerApplyControllerProvider.notifier).setStep(4);

      await notifier.nextStep();

      expect(
        container.read(partnerApplyControllerProvider).currentStep,
        4,
      );
      verifyNever(() => mockRepo.saveDraft(any()));
    });

    // Regression tests for #1599 ──────────────────────────────────────────

    group(
      'Regression #1599: saveDraft failure leaves applicationId null and surfaces error',
      () {
        test(
          'saveDraft failure sets status to AsyncValue.error and keeps applicationId null',
          () async {
            when(() => mockRepo.saveDraft(any())).thenThrow(
              Exception(
                'null value in column "biz_name" violates not-null constraint',
              ),
            );
            final container = buildContainer();
            final notifier = container.read(
              partnerApplyControllerProvider.notifier,
            );

            await notifier.saveDraft();

            final state = container.read(partnerApplyControllerProvider);
            expect(state.applicationId, isNull);
            expect(state.status, isA<AsyncError<Object>>());
          },
        );

        test(
          'submit() with null applicationId sets status to AsyncValue.error instead of silently returning',
          () async {
            // saveDraft throws so applicationId stays null
            when(() => mockRepo.saveDraft(any())).thenThrow(
              Exception('DB error'),
            );
            final container = buildContainer();
            final notifier = container.read(
              partnerApplyControllerProvider.notifier,
            );

            // Populate all fields required by validateAll()
            notifier
              ..updateField('brandName', 'Brand')
              ..updateField('bizName', 'Biz')
              ..updateField('bizNumber', '1234567890')
              ..updateField('representativeName', 'Rep')
              ..updateField('contactPhone', '01012345678')
              ..updateField('contactEmail', 'a@b.com')
              ..updateField('bankName', 'Kakao')
              ..updateField('accountNumber', '1234')
              ..updateField('accountHolder', 'Holder');
            // bizRegistrationPath and bankbookPath via state injection workaround:
            // inject via internal state to satisfy validateAll without file I/O
            container
                .read(partnerApplyControllerProvider.notifier)
                .state = container
                .read(partnerApplyControllerProvider)
                .copyWith(
                  bizRegistrationPath: 'reg.pdf',
                  bankbookPath: 'bank.pdf',
                );

            await notifier.submit();

            final state = container.read(partnerApplyControllerProvider);
            expect(state.applicationId, isNull);
            expect(state.status, isA<AsyncError<Object>>());
          },
        );
      },
    );

    group(
      'Regression #1599: roadAddress/detailAddress handling prevents double-append',
      () {
        test(
          'updateField roadAddress resets detailAddress and sets address = roadAddress',
          () {
            final container = buildContainer();
            final notifier = container.read(
              partnerApplyControllerProvider.notifier,
            );

            notifier.updateField('roadAddress', '서울시 강남구 테헤란로 1');

            final state = container.read(partnerApplyControllerProvider);
            expect(state.roadAddress, '서울시 강남구 테헤란로 1');
            expect(state.detailAddress, '');
            expect(state.address, '서울시 강남구 테헤란로 1');
          },
        );

        test(
          'updateField detailAddress appends to roadAddress in combined address',
          () {
            final container = buildContainer();
            final notifier = container.read(
              partnerApplyControllerProvider.notifier,
            );

            notifier
              ..updateField('roadAddress', '서울시 강남구 테헤란로 1')
              ..updateField('detailAddress', '101호');

            final state = container.read(partnerApplyControllerProvider);
            expect(state.address, '서울시 강남구 테헤란로 1 101호');
          },
        );

        test(
          'changing roadAddress after detailAddress was set resets detailAddress',
          () {
            final container = buildContainer();
            final notifier = container.read(
              partnerApplyControllerProvider.notifier,
            );

            notifier
              ..updateField('roadAddress', '서울시 강남구 테헤란로 1')
              ..updateField('detailAddress', '101호')
              ..updateField('roadAddress', '서울시 서초구 서초대로 2');

            final state = container.read(partnerApplyControllerProvider);
            expect(state.roadAddress, '서울시 서초구 서초대로 2');
            expect(state.detailAddress, '');
            expect(state.address, '서울시 서초구 서초대로 2');
          },
        );

        test(
          'loadDraft restores roadAddress=savedAddress and detailAddress="" preventing step3 double-append',
          () async {
            const savedAddress = '서울시 강남구 테헤란로 100';
            when(() => mockRepo.getMyApplication()).thenAnswer(
              (_) async => const PartnerApplication(
                id: 'app_1',
                userId: 'user_1',
                address: savedAddress,
              ),
            );
            final container = buildContainer();
            final notifier = container.read(
              partnerApplyControllerProvider.notifier,
            );

            await notifier.loadDraft();

            final afterLoad = container.read(partnerApplyControllerProvider);
            expect(afterLoad.roadAddress, savedAddress);
            expect(afterLoad.detailAddress, '');
            expect(afterLoad.address, savedAddress);

            // Simulate user entering detail address on step3 revisit — should NOT double-append
            notifier.updateField('detailAddress', '5층');
            final afterDetail = container.read(partnerApplyControllerProvider);
            expect(afterDetail.address, '$savedAddress 5층');
          },
        );
      },
    );

    group(
      'Regression #1599: saveDraft omits null (empty-string) fields before insert/update',
      () {
        test(
          'saveDraft passes null for empty string fields to repository',
          () async {
            final container = buildContainer();
            final notifier = container.read(
              partnerApplyControllerProvider.notifier,
            );
            // Only brandName is set; all other string fields remain ''
            notifier.updateField('brandName', 'Brand X');

            await notifier.saveDraft();

            final captured =
                verify(
                      () => mockRepo.saveDraft(captureAny()),
                    ).captured.single
                    as PartnerApplication;

            expect(captured.brandName, 'Brand X');
            expect(
              captured.bizName,
              isNull,
              reason: 'empty string must be sent as null',
            );
            expect(
              captured.bizNumber,
              isNull,
              reason: 'empty string must be sent as null',
            );
            expect(
              captured.bankName,
              isNull,
              reason: 'empty string must be sent as null',
            );
            expect(
              captured.contactPhone,
              isNull,
              reason: 'empty string must be sent as null',
            );
            expect(
              captured.contactEmail,
              isNull,
              reason: 'empty string must be sent as null',
            );
          },
        );
      },
    );
  });
}
