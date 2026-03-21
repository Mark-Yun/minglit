import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/iamport/data/repository/iamport_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/supabase_mock_helpers.dart';

void main() {
  group('IamportRepository', () {
    late MockSupabaseClient mockClient;
    late MockFunctionsClient mockFunctions;
    late IamportRepository repository;

    setUp(() {
      mockClient = createMockSupabase(currentUser: MockUser());
      mockFunctions = MockFunctionsClient();
      when(() => mockClient.functions).thenReturn(mockFunctions);
      repository = IamportRepository(mockClient);
    });

    group('verifyCertification', () {
      test('returns response data on success (status 200)', () async {
        final responseData = <String, dynamic>{
          'verified': true,
          'name': '홍길동',
          'unique_key': 'unique_123',
        };
        when(
          () => mockFunctions.invoke(
            'identity-verify',
            body: {'identity_verification_id': 'imp_test_001'},
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: responseData),
        );

        final result = await repository.verifyCertification('imp_test_001');

        expect(result['verified'], isTrue);
        expect(result['name'], '홍길동');
        expect(result['unique_key'], 'unique_123');
      });

      test('wraps non-map response in result key', () async {
        when(
          () => mockFunctions.invoke(
            'identity-verify',
            body: {'identity_verification_id': 'imp_test_002'},
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: 'ok'),
        );

        final result = await repository.verifyCertification('imp_test_002');

        expect(result['result'], 'ok');
      });

      test('throws MinglitUserException on non-200 status', () async {
        when(
          () => mockFunctions.invoke(
            'identity-verify',
            body: {'identity_verification_id': 'imp_fail_001'},
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 400, data: 'error'),
        );

        expect(
          () => repository.verifyCertification('imp_fail_001'),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws MinglitUserException on 500 status', () async {
        when(
          () => mockFunctions.invoke(
            'identity-verify',
            body: {'identity_verification_id': 'imp_fail_002'},
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 500),
        );

        expect(
          () => repository.verifyCertification('imp_fail_002'),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws MinglitAuthException when user is not logged in', () {
        final noAuthClient = createMockSupabase();
        final noAuthRepo = IamportRepository(noAuthClient);

        expect(
          () => noAuthRepo.verifyCertification('imp_no_auth'),
          throwsA(isA<MinglitAuthException>()),
        );
      });

      test('rethrows unexpected exceptions', () async {
        when(
          () => mockFunctions.invoke(
            'identity-verify',
            body: {'identity_verification_id': 'imp_crash'},
          ),
        ).thenThrow(Exception('network failure'));

        expect(
          () => repository.verifyCertification('imp_crash'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
