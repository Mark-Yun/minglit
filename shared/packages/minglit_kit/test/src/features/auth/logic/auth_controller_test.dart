import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/auth/logic/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_utils.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  ProviderContainer createTestContainer() {
    return createContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('AuthController', () {
    test('initial state is AsyncData(void)', () async {
      final container = createTestContainer();

      // Allow build to complete
      await container.read(authControllerProvider.future);

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncData<void>>());
    });

    group('signInWithGoogle', () {
      test('sets loading then error on failure', () async {
        when(
          () => mockRepo.signInWithGoogle(redirectTo: any(named: 'redirectTo')),
        ).thenThrow(Exception('Google sign-in failed'));

        final container = createTestContainer();
        await container.read(authControllerProvider.future);
        final notifier =
            container.read(authControllerProvider.notifier);

        await notifier.signInWithGoogle();

        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });
    });

    group('signInWithEmail', () {
      test('calls repository signInWithEmail', () async {
        when(
          () => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {});

        final container = createTestContainer();
        await container.read(authControllerProvider.future);
        final notifier =
            container.read(authControllerProvider.notifier);

        await notifier.signInWithEmail(
          email: 'test@test.com',
          password: 'password123',
        );

        verify(
          () => mockRepo.signInWithEmail(
            email: 'test@test.com',
            password: 'password123',
          ),
        ).called(1);
      });

      test('sets error state on failure', () async {
        when(
          () => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('Invalid credentials'));

        final container = createTestContainer();
        await container.read(authControllerProvider.future);
        final notifier =
            container.read(authControllerProvider.notifier);

        await notifier.signInWithEmail(
          email: 'bad@test.com',
          password: 'wrong',
        );

        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });
    });

    group('signInWithApple', () {
      test('sets error state on failure', () async {
        when(
          () => mockRepo.signInWithApple(
            redirectTo: any(named: 'redirectTo'),
          ),
        ).thenThrow(Exception('Apple sign-in failed'));

        final container = createTestContainer();
        await container.read(authControllerProvider.future);
        final notifier =
            container.read(authControllerProvider.notifier);

        await notifier.signInWithApple();

        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });
    });

    group('signInWithKakao', () {
      test('sets error state on failure', () async {
        when(
          () => mockRepo.signInWithKakao(
            redirectTo: any(named: 'redirectTo'),
          ),
        ).thenThrow(Exception('Kakao sign-in failed'));

        final container = createTestContainer();
        await container.read(authControllerProvider.future);
        final notifier =
            container.read(authControllerProvider.notifier);

        await notifier.signInWithKakao();

        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });
    });

    group('signOut', () {
      test('calls repository signOut', () async {
        when(() => mockRepo.signOut()).thenAnswer((_) async {});

        final container = createTestContainer();
        await container.read(authControllerProvider.future);
        final notifier =
            container.read(authControllerProvider.notifier);

        await notifier.signOut();

        verify(() => mockRepo.signOut()).called(1);
      });

      test('sets error state on failure', () async {
        when(() => mockRepo.signOut())
            .thenThrow(Exception('Sign out failed'));

        final container = createTestContainer();
        await container.read(authControllerProvider.future);
        final notifier =
            container.read(authControllerProvider.notifier);

        await notifier.signOut();

        final state = container.read(authControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });
    });
  });
}
