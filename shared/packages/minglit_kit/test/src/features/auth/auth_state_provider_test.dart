import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/auth/logic/auth_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_utils.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('authStateChangesProvider', () {
    test('is initially AsyncLoading before stream emits any value', () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      when(
        () => mockAuthRepo.onAuthStateChange,
      ).thenAnswer((_) => controller.stream);

      final container = createContainer(
        overrides: [authRepositoryProvider.overrideWith((ref) => mockAuthRepo)],
      );

      // StreamProvider starts as AsyncLoading until the first value arrives
      final state = container.read(authStateChangesProvider);
      expect(state, isA<AsyncLoading<AuthState>>());
    });
  });

  group('currentUserProvider', () {
    test('returns null when repository has no current user', () async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      when(
        () => mockAuthRepo.onAuthStateChange,
      ).thenAnswer((_) => controller.stream);
      when(() => mockAuthRepo.currentUser).thenReturn(null);

      final container = createContainer(
        overrides: [authRepositoryProvider.overrideWith((ref) => mockAuthRepo)],
      );

      final user = container.read(currentUserProvider);
      expect(user, isNull);
    });
  });

  group('AuthController', () {
    test('signInWithGoogle calls repository and sets AsyncData on success '
        '(non-web environment)', () async {
      when(
        () =>
            mockAuthRepo.signInWithGoogle(redirectTo: any(named: 'redirectTo')),
      ).thenAnswer((_) async {});

      final container = createContainer(
        overrides: [authRepositoryProvider.overrideWith((ref) => mockAuthRepo)],
      );

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signInWithGoogle();

      verify(
        () =>
            mockAuthRepo.signInWithGoogle(redirectTo: any(named: 'redirectTo')),
      ).called(1);

      // In a non-web test environment (kIsWeb == false), the controller
      // explicitly sets AsyncData(null) after a successful Google sign-in.
      expect(
        container.read(authControllerProvider),
        const AsyncData<void>(null),
      );
    });

    test('signInWithApple sets AsyncError when repository throws', () async {
      final exception = Exception('Apple sign-in failed');
      when(
        () =>
            mockAuthRepo.signInWithApple(redirectTo: any(named: 'redirectTo')),
      ).thenThrow(exception);

      final container = createContainer(
        overrides: [authRepositoryProvider.overrideWith((ref) => mockAuthRepo)],
      );

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signInWithApple();

      verify(
        () =>
            mockAuthRepo.signInWithApple(redirectTo: any(named: 'redirectTo')),
      ).called(1);

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncError<void>>());
      expect(state.error, exception);
    });

    test(
      'signInWithKakao calls repository and remains AsyncLoading after success '
      '(awaits OAuth redirect callback on all platforms)',
      () async {
        when(
          () => mockAuthRepo.signInWithKakao(
            redirectTo: any(named: 'redirectTo'),
          ),
        ).thenAnswer((_) async {});

        final container = createContainer(
          overrides: [
            authRepositoryProvider.overrideWith((ref) => mockAuthRepo),
          ],
        );

        final notifier = container.read(authControllerProvider.notifier);
        await notifier.signInWithKakao();

        verify(
          () => mockAuthRepo.signInWithKakao(
            redirectTo: any(named: 'redirectTo'),
          ),
        ).called(1);

        // Kakao uses web OAuth redirect on ALL platforms. The controller does NOT
        // set AsyncData after a successful call — auth completion arrives later
        // via onAuthStateChange after the OAuth callback redirects back.
        expect(
          container.read(authControllerProvider),
          isA<AsyncLoading<void>>(),
        );
      },
    );
  });
}
