import 'package:app_partner/src/features/verification/create/create_verification_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  late MockPartnerRepository mockPartnerRepo;
  late MockVerificationRepository mockVerificationRepo;

  setUpAll(() {
    registerFallbackValue(
      const Verification(
        id: '',
        partnerId: '',
        category: VerificationCategory.etc,
        internalName: '',
        displayName: '',
      ),
    );
  });

  setUp(() {
    mockPartnerRepo = MockPartnerRepository();
    mockVerificationRepo = MockVerificationRepository();
  });

  ProviderContainer makeContainer() {
    return createContainer(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
        verificationRepositoryProvider
            .overrideWithValue(mockVerificationRepo),
      ],
    );
  }

  group('CreateVerificationController', () {
    test('initial state has empty fields', () {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final state = container.read(createVerificationControllerProvider);
      expect(state.displayName, isEmpty);
      expect(state.internalName, isEmpty);
      expect(state.description, isEmpty);
      expect(state.fields, isEmpty);
      expect(state.error, isNull);
    });

    test('updateDisplayName updates state', () {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container
          .read(createVerificationControllerProvider.notifier)
          .updateDisplayName('직장 인증');

      expect(
        container.read(createVerificationControllerProvider).displayName,
        '직장 인증',
      );
    });

    test('updateInternalName updates state', () {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container
          .read(createVerificationControllerProvider.notifier)
          .updateInternalName('career_check');

      expect(
        container.read(createVerificationControllerProvider).internalName,
        'career_check',
      );
    });

    test('updateDescription updates state', () {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container
          .read(createVerificationControllerProvider.notifier)
          .updateDescription('재직증명서 제출');

      expect(
        container.read(createVerificationControllerProvider).description,
        '재직증명서 제출',
      );
    });

    test('addField appends a new field', () {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container
          .read(createVerificationControllerProvider.notifier)
          .addField('text');

      final state = container.read(createVerificationControllerProvider);
      expect(state.fields.length, 1);
      expect(state.fields.first.type, 'text');
      expect(state.fields.first.label, isEmpty);
    });

    test('removeField removes field at index', () {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final notifier =
          container.read(createVerificationControllerProvider.notifier);
      notifier.addField('text');
      notifier.addField('file');

      expect(
        container.read(createVerificationControllerProvider).fields.length,
        2,
      );

      notifier.removeField(0);

      final state = container.read(createVerificationControllerProvider);
      expect(state.fields.length, 1);
      expect(state.fields.first.type, 'file');
    });

    test('updateField replaces field at index', () {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final notifier =
          container.read(createVerificationControllerProvider.notifier);
      notifier.addField('text');

      final original =
          container.read(createVerificationControllerProvider).fields.first;
      final updated = original.copyWith(label: '회사명');
      notifier.updateField(0, updated);

      final state = container.read(createVerificationControllerProvider);
      expect(state.fields.first.label, '회사명');
    });

    test('reorderFields moves field correctly', () {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final notifier =
          container.read(createVerificationControllerProvider.notifier);
      notifier.addField('text');
      notifier.addField('file');
      notifier.addField('date');

      // Move item at index 0 to index 2
      notifier.reorderFields(0, 2);

      final state = container.read(createVerificationControllerProvider);
      expect(state.fields[0].type, 'file');
      expect(state.fields[1].type, 'text');
      expect(state.fields[2].type, 'date');
    });

    test('submit with empty fields returns false and sets error', () async {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final result = await container
          .read(createVerificationControllerProvider.notifier)
          .submit('partner-1');

      expect(result, isFalse);
      expect(
        container.read(createVerificationControllerProvider).error,
        '적어도 하나의 입력 필드가 필요합니다.',
      );
    });

    test('submit success with partnerId returns true', () async {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      when(() => mockVerificationRepo.createVerification(any()))
          .thenAnswer((_) async => const Verification(
                id: 'new-v-1',
                partnerId: 'partner-1',
                category: VerificationCategory.etc,
                internalName: 'test',
                displayName: 'Test',
              ));

      final notifier =
          container.read(createVerificationControllerProvider.notifier);
      notifier.updateDisplayName('Test');
      notifier.updateInternalName('test');
      notifier.addField('text');

      final result = await notifier.submit('partner-1');

      expect(result, isTrue);
      verify(() => mockVerificationRepo.createVerification(any())).called(1);
    });

    test('submit with null partnerId fetches managed partners', () async {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      when(() => mockPartnerRepo.getMyManagedPartners()).thenAnswer(
        (_) async => [const Partner(id: 'auto-partner', name: 'Auto')],
      );
      when(() => mockVerificationRepo.createVerification(any()))
          .thenAnswer((_) async => const Verification(
                id: 'new-v-1',
                partnerId: 'auto-partner',
                category: VerificationCategory.etc,
                internalName: 'test',
                displayName: 'Test',
              ));

      final notifier =
          container.read(createVerificationControllerProvider.notifier);
      notifier.addField('text');

      final result = await notifier.submit(null);

      expect(result, isTrue);
      verify(() => mockPartnerRepo.getMyManagedPartners()).called(1);
    });

    test('submit with null partnerId and no managed partners returns false',
        () async {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      when(() => mockPartnerRepo.getMyManagedPartners())
          .thenAnswer((_) async => []);

      final notifier =
          container.read(createVerificationControllerProvider.notifier);
      notifier.addField('text');

      final result = await notifier.submit(null);

      expect(result, isFalse);
      expect(
        container.read(createVerificationControllerProvider).error,
        contains('파트너 정보를 찾을 수 없습니다'),
      );
    });

    test('submit error sets error message', () async {
      final container = makeContainer();
      final sub = container.listen(
        createVerificationControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      when(() => mockVerificationRepo.createVerification(any()))
          .thenThrow(Exception('create failed'));

      final notifier =
          container.read(createVerificationControllerProvider.notifier);
      notifier.addField('text');

      final result = await notifier.submit('partner-1');

      expect(result, isFalse);
      expect(
        container.read(createVerificationControllerProvider).error,
        isNotNull,
      );
    });
  });
}
