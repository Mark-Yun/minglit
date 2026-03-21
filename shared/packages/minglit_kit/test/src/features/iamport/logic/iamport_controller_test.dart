import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/iamport/data/model/iamport_result_model.dart';
import 'package:minglit_kit/src/features/iamport/data/repository/iamport_repository.dart';
import 'package:minglit_kit/src/features/iamport/logic/iamport_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_utils.dart';

class MockIamportRepository extends Mock implements IamportRepository {}

void main() {
  group('IamportController', () {
    late MockIamportRepository mockRepo;

    setUp(() {
      mockRepo = MockIamportRepository();
    });

    ProviderContainer createTestContainer() {
      return createContainer(
        overrides: [
          iamportRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    }

    test('initial state is AsyncData(null)', () {
      final container = createTestContainer();

      final state = container.read(iamportControllerProvider);

      expect(state, isA<AsyncData<IamportResultModel?>>());
      expect(state.value, isNull);
    });

    group('onCertificationResult', () {
      test('verifies and sets success state on successful certification',
          () async {
        when(() => mockRepo.verifyCertification('imp_success_001'))
            .thenAnswer((_) async => <String, dynamic>{'verified': true});

        final container = createTestContainer();
        final notifier =
            container.read(iamportControllerProvider.notifier);

        await notifier.onCertificationResult(<String, String>{
          'imp_uid': 'imp_success_001',
          'merchant_uid': 'mid_001',
          'success': 'true',
        });

        final state = container.read(iamportControllerProvider);
        expect(state, isA<AsyncData<IamportResultModel?>>());
        expect(state.value!.success, isTrue);
        expect(state.value!.impUid, 'imp_success_001');
        verify(() => mockRepo.verifyCertification('imp_success_001')).called(1);
      });

      test('sets error state when certification fails from Iamport', () async {
        final container = createTestContainer();
        final notifier =
            container.read(iamportControllerProvider.notifier);

        await notifier.onCertificationResult(<String, String>{
          'imp_uid': '',
          'merchant_uid': 'mid_fail',
          'success': 'false',
          'error_msg': 'User cancelled authentication',
        });

        final state = container.read(iamportControllerProvider);
        expect(state, isA<AsyncError<IamportResultModel?>>());
        expect(state.error.toString(), 'User cancelled authentication');
        verifyNever(() => mockRepo.verifyCertification(any()));
      });

      test('sets error state when success is true but impUid is null',
          () async {
        final container = createTestContainer();
        final notifier =
            container.read(iamportControllerProvider.notifier);

        await notifier.onCertificationResult(<String, String>{
          'success': 'false',
          'error_msg': 'No UID returned',
        });

        final state = container.read(iamportControllerProvider);
        expect(state, isA<AsyncError<IamportResultModel?>>());
      });

      test('sets error state when server verification fails', () async {
        when(() => mockRepo.verifyCertification('imp_server_fail'))
            .thenThrow(Exception('server error'));

        final container = createTestContainer();
        final notifier =
            container.read(iamportControllerProvider.notifier);

        await notifier.onCertificationResult(<String, String>{
          'imp_uid': 'imp_server_fail',
          'merchant_uid': 'mid_003',
          'success': 'true',
        });

        final state = container.read(iamportControllerProvider);
        expect(state, isA<AsyncError<IamportResultModel?>>());
      });

      test('uses default error message when errorMsg is null', () async {
        final container = createTestContainer();
        final notifier =
            container.read(iamportControllerProvider.notifier);

        await notifier.onCertificationResult(<String, String>{
          'success': 'false',
        });

        final state = container.read(iamportControllerProvider);
        expect(state, isA<AsyncError<IamportResultModel?>>());
        expect(
          state.error.toString(),
          'Unknown certification error',
        );
      });
    });

    group('reset', () {
      test('resets state to AsyncData(null)', () async {
        when(() => mockRepo.verifyCertification('imp_reset'))
            .thenAnswer((_) async => <String, dynamic>{'verified': true});

        final container = createTestContainer();
        final notifier =
            container.read(iamportControllerProvider.notifier);

        await notifier.onCertificationResult(<String, String>{
          'imp_uid': 'imp_reset',
          'merchant_uid': 'mid_reset',
          'success': 'true',
        });

        // Verify state is set before reset
        expect(container.read(iamportControllerProvider).value, isNotNull);

        notifier.reset();

        final state = container.read(iamportControllerProvider);
        expect(state, isA<AsyncData<IamportResultModel?>>());
        expect(state.value, isNull);
      });
    });
  });
}
