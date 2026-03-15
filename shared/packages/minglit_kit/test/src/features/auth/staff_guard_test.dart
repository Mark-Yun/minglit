import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/staff_repository.dart';
import 'package:minglit_kit/src/features/auth/logic/staff_guard_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_utils.dart';

class MockStaffRepository extends Mock implements StaffRepository {}

class MockUser extends Mock implements User {}

void main() {
  group('StaffGuard', () {
    late MockStaffRepository mockRepo;

    setUp(() {
      mockRepo = MockStaffRepository();
    });

    test(
      'build() returns null when verifyStaffStatus() returns null (not staff)',
      () async {
        when(() => mockRepo.verifyStaffStatus()).thenAnswer((_) async => null);

        final container = createContainer(
          overrides: [staffRepositoryProvider.overrideWith((ref) => mockRepo)],
        );

        final result = await container.read(staffGuardProvider.future);

        expect(result, isNull);
        verify(() => mockRepo.verifyStaffStatus()).called(1);
      },
    );

    test(
      'build() returns User when verifyStaffStatus() returns a user (is staff)',
      () async {
        final mockUser = MockUser();
        when(
          () => mockRepo.verifyStaffStatus(),
        ).thenAnswer((_) async => mockUser);

        final container = createContainer(
          overrides: [staffRepositoryProvider.overrideWith((ref) => mockRepo)],
        );

        final result = await container.read(staffGuardProvider.future);

        expect(result, equals(mockUser));
        verify(() => mockRepo.verifyStaffStatus()).called(1);
      },
    );

    test(
      'reset() clears staff token and sets state to AsyncData(null)',
      () async {
        when(() => mockRepo.verifyStaffStatus()).thenAnswer((_) async => null);
        when(() => mockRepo.clearStaffToken()).thenAnswer((_) async {});

        final container = createContainer(
          overrides: [staffRepositoryProvider.overrideWith((ref) => mockRepo)],
        );

        // Wait for build to complete
        await container.read(staffGuardProvider.future);

        // Call reset
        await container.read(staffGuardProvider.notifier).reset();

        final stateAfterReset = container.read(staffGuardProvider);
        expect(stateAfterReset, equals(const AsyncData<User?>(null)));
        verify(() => mockRepo.clearStaffToken()).called(1);
      },
    );

    test(
      'requestMagicLink() calls repository sendMagicLink with the given email',
      () async {
        const email = 'staff@minglit.com';
        when(() => mockRepo.verifyStaffStatus()).thenAnswer((_) async => null);
        when(() => mockRepo.sendMagicLink(email)).thenAnswer((_) async {});

        final container = createContainer(
          overrides: [staffRepositoryProvider.overrideWith((ref) => mockRepo)],
        );

        // Wait for build to complete
        await container.read(staffGuardProvider.future);

        await container
            .read(staffGuardProvider.notifier)
            .requestMagicLink(email);

        verify(() => mockRepo.sendMagicLink(email)).called(1);
      },
    );
  });
}
