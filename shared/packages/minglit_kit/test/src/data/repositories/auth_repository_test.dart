import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRepository repository;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser();
    mockClient = createMockSupabase(currentUser: mockUser);
    mockAuth = mockClient.auth as MockGoTrueClient;
    repository = AuthRepository(supabase: mockClient);
  });

  group('AuthRepository', () {
    group('currentUser', () {
      test('returns current user from auth client', () {
        when(() => mockUser.id).thenReturn('user_1');

        final user = repository.currentUser;

        expect(user, isNotNull);
        expect(user!.id, 'user_1');
      });

      test('returns null when not authenticated', () {
        when(() => mockAuth.currentUser).thenReturn(null);

        expect(repository.currentUser, isNull);
      });
    });

    group('onAuthStateChange', () {
      test('returns auth state stream from auth client', () {
        final controller = StreamController<AuthState>();
        when(
          () => mockAuth.onAuthStateChange,
        ).thenAnswer((_) => controller.stream);

        expect(repository.onAuthStateChange, isA<Stream<AuthState>>());
        unawaited(controller.close());
      });
    });

    group('signInWithEmail', () {
      test('calls signInWithPassword with credentials', () async {
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        await repository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        verify(
          () => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
      });

      test('rethrows AuthException on failure', () async {
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Invalid credentials'));

        expect(
          () => repository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrong',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('completes successfully', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await expectLater(repository.signOut(), completes);

        verify(() => mockAuth.signOut()).called(1);
      });

      test('rethrows when supabase signOut fails', () async {
        when(
          () => mockAuth.signOut(),
        ).thenThrow(Exception('signout failed'));

        await expectLater(
          repository.signOut(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
