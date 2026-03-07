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
  });
}
