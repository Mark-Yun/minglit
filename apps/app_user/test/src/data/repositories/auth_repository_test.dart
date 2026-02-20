import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('AuthController.signInWithKakao', () {
    test('calls repository signInWithKakao', () async {
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

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithKakao();

      verify(
        () => mockAuthRepo.signInWithKakao(
          redirectTo: any(named: 'redirectTo'),
        ),
      ).called(1);
    });

    test('passes redirectTo to repository', () async {
      when(
        () => mockAuthRepo.signInWithKakao(
          redirectTo: 'https://example.com/callback',
        ),
      ).thenAnswer((_) async {});

      final container = createContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockAuthRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithKakao(
        redirectTo: 'https://example.com/callback',
      );

      verify(
        () => mockAuthRepo.signInWithKakao(
          redirectTo: 'https://example.com/callback',
        ),
      ).called(1);
    });

    test('sets state to AsyncError when signInWithKakao fails', () async {
      final exception = Exception('Kakao login failed');
      when(
        () => mockAuthRepo.signInWithKakao(
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenThrow(exception);

      final container = createContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockAuthRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithKakao();

      verify(
        () => mockAuthRepo.signInWithKakao(
          redirectTo: any(named: 'redirectTo'),
        ),
      ).called(1);

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncError<void>>());
      expect(state.error, exception);
    });
  });
}
