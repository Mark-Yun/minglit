import 'dart:async' show unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/identity_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late IdentityRepository repository;

  final mockUser = MockUser();

  late MockFunctionsClient mockFunctions;

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = IdentityRepository(mockClient);
  });

  group('IdentityRepository', () {
    group('verifyIdentity', () {
      test('throws MinglitAuthException when user not logged in', () async {
        mockClient = createMockSupabase(); // No user
        repository = IdentityRepository(mockClient);

        expect(
          () => repository.verifyIdentity(
            identityVerificationId: 'id_verify_1',
          ),
          throwsA(isA<MinglitAuthException>()),
        );
      });

      test('succeeds when edge function returns 200', () async {
        when(
          () => mockFunctions.invoke(
            'verify-identity-v1',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'ok': true}),
        );

        await expectLater(
          repository.verifyIdentity(
            identityVerificationId: 'id_verify_1',
          ),
          completes,
        );
      });

      test(
        'throws MinglitUserException when edge function returns non-200',
        () async {
          when(
            () => mockFunctions.invoke(
              'verify-identity-v1',
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async =>
                FunctionResponse(status: 400, data: 'Invalid verification'),
          );

          expect(
            () => repository.verifyIdentity(
              identityVerificationId: 'invalid',
            ),
            throwsA(isA<MinglitUserException>()),
          );
        },
      );
    });

    group('isVerified', () {
      test('returns true when user is verified', () async {
        unawaited(
          mockTable(
            mockClient,
            'user_profiles',
            singleData: {'is_verified': true},
          ),
        );

        final result = await repository.isVerified();
        expect(result, isTrue);
      });

      test('returns false when user is not verified', () async {
        unawaited(
          mockTable(
            mockClient,
            'user_profiles',
            singleData: {'is_verified': false},
          ),
        );

        final result = await repository.isVerified();
        expect(result, isFalse);
      });

      test('returns false when user not logged in', () async {
        mockClient = createMockSupabase(); // No user
        repository = IdentityRepository(mockClient);

        final result = await repository.isVerified();
        expect(result, isFalse);
      });
    });
  });
}
