import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('AuthController', () {
    test('signOut calls repository signOut', () async {
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});

      final container = createContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockAuthRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();

      verify(() => mockAuthRepo.signOut()).called(1);
      expect(
        container.read(authControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('signInWithEmail calls repository signInWithEmail', () async {
      when(
        () => mockAuthRepo.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => {},
      ); // AuthResponse not needed as it returns void

      final container = createContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockAuthRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password',
      );

      verify(
        () => mockAuthRepo.signInWithEmail(
          email: 'test@example.com',
          password: 'password',
        ),
      ).called(1);
    });

    test('sets state to AsyncError when signOut fails', () async {
      final exception = Exception('Logout failed');
      when(() => mockAuthRepo.signOut()).thenThrow(exception);

      final container = createContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockAuthRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();

      verify(() => mockAuthRepo.signOut()).called(1);

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncError<void>>());
      expect(state.error, exception);
    });

    test('signOut returns early if ref is disposed', () async {
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});

      final container = createContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockAuthRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      
      // Simulate ref being disposed by invalidating the provider
      container.invalidate(authControllerProvider);
      
      // This should not throw even though ref is disposed
      await controller.signOut();
      
      verify(() => mockAuthRepo.signOut()).called(1);
    });
  });
}
