import 'package:app_partner/src/features/verification/create/create_verification_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

void main() {
  late MockVerificationRepository mockVerificationRepo;
  late MockPartnerRepository mockPartnerRepo;

  setUpAll(() {
    registerFallbackValue(
      const Verification(
        id: '',
        partnerId: '',
        category: VerificationCategory.etc,
        internalName: '',
        displayName: '',
        description: '',
        iconKey: '',
        formSchema: [],
      ),
    );
  });

  setUp(() {
    mockVerificationRepo = MockVerificationRepository();
    mockPartnerRepo = MockPartnerRepository();

    when(() => mockVerificationRepo.createVerification(any()))
        .thenAnswer((_) async => const Verification(
              id: 'new-id',
              partnerId: 'p1',
              category: VerificationCategory.etc,
              internalName: '',
              displayName: '',
              description: '',
              iconKey: '',
              formSchema: [],
            ));
    when(() => mockVerificationRepo.getPartnerVerifications(any()))
        .thenAnswer((_) async => []);
    when(
      () => mockVerificationRepo.getGlobalVerifications(),
    ).thenAnswer((_) async => []);
  });

  ProviderContainer buildContainer() {
    return createContainer(
      overrides: [
        verificationRepositoryProvider.overrideWithValue(mockVerificationRepo),
        partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
      ],
    );
  }

  group('CreateVerificationController', () {
    test('initial state has empty fields and no error', () {
      final container = buildContainer();
      final state =
          container.read(createVerificationControllerProvider);

      expect(state.displayName, isEmpty);
      expect(state.internalName, isEmpty);
      expect(state.description, isEmpty);
      expect(state.fields, isEmpty);
      expect(state.error, isNull);
    });

    test('updateDisplayName updates state', () {
      final container = buildContainer();
      final notifier =
          container.read(createVerificationControllerProvider.notifier);

      notifier.updateDisplayName('My Verification');

      expect(
        container.read(createVerificationControllerProvider).displayName,
        'My Verification',
      );
    });

    test('addField appends a new field', () {
      final container = buildContainer();
      final notifier =
          container.read(createVerificationControllerProvider.notifier);

      notifier.addField('text');

      final state = container.read(createVerificationControllerProvider);
      expect(state.fields, hasLength(1));
      expect(state.fields.first.type, 'text');
    });

    test('removeField removes the field at given index', () {
      final container = buildContainer();
      final notifier =
          container.read(createVerificationControllerProvider.notifier);

      notifier
        ..addField('text')
        ..addField('number');

      notifier.removeField(0);

      final state = container.read(createVerificationControllerProvider);
      expect(state.fields, hasLength(1));
      expect(state.fields.first.type, 'number');
    });

    test('submit returns false and sets error when fields are empty', () async {
      final container = buildContainer();
      final notifier =
          container.read(createVerificationControllerProvider.notifier);

      final result = await notifier.submit('partner_1');

      expect(result, isFalse);
      expect(
        container.read(createVerificationControllerProvider).error,
        isNotNull,
      );
    });
  });
}
