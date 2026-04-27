import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/user_repository.dart';
import 'package:minglit_kit/src/logic/providers/user_profile_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_utils.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockUserRepository mockRepo;
  late _MockUser mockUser;

  const testProfile = UserProfile(
    id: 'user_1',
    name: '홍길동',
    username: 'gildong',
  );

  setUp(() {
    mockRepo = _MockUserRepository();
    mockUser = _MockUser();
    when(() => mockUser.id).thenReturn('user_1');
  });

  group('currentUserProfileProvider', () {
    // Fix #1948: must route through UserRepository, not direct Supabase
    test('returns null when user is not logged in', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          userRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final result = await container.read(currentUserProfileProvider.future);

      expect(result, isNull);
      verifyNever(() => mockRepo.getUserProfile(any()));
    });

    test(
      'returns profile from UserRepository when user is logged in',
      () async {
        when(
          () => mockRepo.getUserProfile('user_1'),
        ).thenAnswer((_) async => testProfile);

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            userRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        final result = await container.read(currentUserProfileProvider.future);

        expect(result, isNotNull);
        expect(result!.id, 'user_1');
        expect(result.name, '홍길동');
        verify(() => mockRepo.getUserProfile('user_1')).called(1);
      },
    );

    // Fix #1948: PGRST116 (no rows) should return null, not crash
    test('returns null when UserRepository returns null (PGRST116)', () async {
      when(
        () => mockRepo.getUserProfile('user_1'),
      ).thenAnswer((_) async => null);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          userRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final result = await container.read(currentUserProfileProvider.future);

      expect(result, isNull);
    });

    // Fix #1948: non-PGRST116 errors must propagate as AsyncError.
    // Note: .future stays pending on keepAlive providers with Riverpod 3 retry
    // logic, so we trigger build, pump the event queue (first attempt), then
    // read the AsyncValue state directly.
    test('propagates error when UserRepository throws', () async {
      when(
        () => mockRepo.getUserProfile('user_1'),
      ).thenAnswer((_) async => throw Exception('network error'));

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          userRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      container.read(currentUserProfileProvider);
      await pumpEventQueue();

      final state = container.read(currentUserProfileProvider);
      expect(state.hasError, isTrue);
    });
  });
}
