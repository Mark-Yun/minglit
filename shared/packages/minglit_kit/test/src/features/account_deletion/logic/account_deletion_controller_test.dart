import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/deletion_status.dart';
import 'package:minglit_kit/src/data/models/withdrawal_reason.dart';
import 'package:minglit_kit/src/data/repositories/account_repository.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/account_deletion/logic/account_deletion_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_utils.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockAccountRepository mockRepository;
  late MockUser mockUser;

  const pendingStatus = DeletionStatus(isPending: true);
  const activeStatus = DeletionStatus();

  setUp(() {
    mockRepository = MockAccountRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_1');
  });

  ProviderContainer createTestContainer({User? user}) {
    return createContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockRepository),
        currentUserProvider.overrideWithValue(user),
      ],
    );
  }

  group('AccountDeletionController', () {
    test('returns null when user is not logged in', () async {
      final container = createTestContainer();

      final result = await container.read(
        accountDeletionControllerProvider.future,
      );

      expect(result, isNull);
    });

    test('loads current deletion status from repository', () async {
      when(
        () => mockRepository.getDeletionStatus(),
      ).thenAnswer((_) async => activeStatus);

      final container = createTestContainer(user: mockUser);

      final result = await container.read(
        accountDeletionControllerProvider.future,
      );

      expect(result, activeStatus);
      verify(() => mockRepository.getDeletionStatus()).called(1);
    });

    test('requestDeletion updates state with pending status', () async {
      when(
        () => mockRepository.getDeletionStatus(),
      ).thenAnswer((_) async => activeStatus);
      when(
        () => mockRepository.deleteAccount(any()),
      ).thenAnswer((_) async => pendingStatus);

      final container = createTestContainer(user: mockUser);
      await container.read(accountDeletionControllerProvider.future);

      await container
          .read(accountDeletionControllerProvider.notifier)
          .requestDeletion(
            reason: const WithdrawalReason(
              reasonCode: WithdrawalReasonCode.noLongerUse,
            ),
          );

      expect(
        container.read(accountDeletionControllerProvider).value,
        pendingStatus,
      );
      verify(() => mockRepository.deleteAccount(any())).called(1);
    });

    test('requestDeletion stores AsyncError on failure', () async {
      when(
        () => mockRepository.getDeletionStatus(),
      ).thenAnswer((_) async => activeStatus);
      when(
        () => mockRepository.deleteAccount(any()),
      ).thenThrow(const AuthException('boom'));

      final container = createTestContainer(user: mockUser);
      await container.read(accountDeletionControllerProvider.future);

      await container
          .read(accountDeletionControllerProvider.notifier)
          .requestDeletion();

      expect(
        container.read(accountDeletionControllerProvider),
        isA<AsyncError<DeletionStatus?>>(),
      );
    });

    test('cancelDeletion reloads status after success', () async {
      var callCount = 0;
      when(() => mockRepository.getDeletionStatus()).thenAnswer((_) async {
        callCount += 1;
        return callCount == 1 ? pendingStatus : activeStatus;
      });
      when(() => mockRepository.cancelDeletion()).thenAnswer((_) async {});

      final container = createTestContainer(user: mockUser);
      await container.read(accountDeletionControllerProvider.future);

      await container
          .read(accountDeletionControllerProvider.notifier)
          .cancelDeletion();

      expect(
        container.read(accountDeletionControllerProvider).value,
        activeStatus,
      );
      verify(() => mockRepository.cancelDeletion()).called(1);
      expect(callCount, 2);
    });

    test('reauthenticate keeps previous state on success', () async {
      when(
        () => mockRepository.getDeletionStatus(),
      ).thenAnswer((_) async => activeStatus);
      when(() => mockRepository.reauthenticate('pw')).thenAnswer((_) async {});

      final container = createTestContainer(user: mockUser);
      await container.read(accountDeletionControllerProvider.future);

      await container
          .read(accountDeletionControllerProvider.notifier)
          .reauthenticate('pw');

      expect(
        container.read(accountDeletionControllerProvider).value,
        activeStatus,
      );
    });

    test('reauthenticate stores AsyncError on failure', () async {
      when(
        () => mockRepository.getDeletionStatus(),
      ).thenAnswer((_) async => activeStatus);
      when(
        () => mockRepository.reauthenticate('pw'),
      ).thenThrow(const AuthException('invalid'));

      final container = createTestContainer(user: mockUser);
      await container.read(accountDeletionControllerProvider.future);

      await expectLater(
        () => container
            .read(accountDeletionControllerProvider.notifier)
            .reauthenticate('pw'),
        throwsA(isA<AuthException>()),
      );

      expect(
        container.read(accountDeletionControllerProvider),
        isA<AsyncError<DeletionStatus?>>(),
      );
    });
  });
}
