import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/user_repository.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late SupabaseUserRepository repository;

  final now = DateTime.now();

  final userProfileJson = {
    'id': 'user_1',
    'name': '홍길동',
    'username': 'gildong',
    'phone_number': '010-1234-5678',
    'gender': 'male',
    'birth_date': '1990-01-15T00:00:00.000Z',
    'is_verified': true,
    'birth_year': 1990,
    'avatar_url': 'https://example.com/avatar.png',
    'profile_image_url': 'https://example.com/profile.png',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  setUp(() {
    mockClient = createMockSupabase();
    repository = SupabaseUserRepository(supabase: mockClient);
  });

  group('SupabaseUserRepository', () {
    group('getUserProfile', () {
      test('returns UserProfile when found', () async {
        unawaited(
          mockTable(mockClient, 'user_profiles', singleData: userProfileJson),
        );

        final result = await repository.getUserProfile('user_1');

        expect(result, isNotNull);
        expect(result!.id, 'user_1');
        expect(result.name, '홍길동');
        expect(result.username, 'gildong');
        expect(result.phoneNumber, '010-1234-5678');
        expect(result.gender, 'male');
        expect(result.isVerified, isTrue);
        expect(result.birthYear, 1990);
      });

      test('returns null on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'user_profiles',
            shouldThrow: Exception('not found'),
          ),
        );

        final result = await repository.getUserProfile('user_unknown');

        expect(result, isNull);
      });
    });

    group('getApprovedVerificationIds', () {
      test('returns list of verification IDs', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_verified_users',
            selectData: [
              {'verification_id': 'v_1'},
              {'verification_id': 'v_2'},
              {'verification_id': 'v_3'},
            ],
          ),
        );

        final result = await repository.getApprovedVerificationIds('user_1');

        expect(result, hasLength(3));
        expect(result, containsAll(['v_1', 'v_2', 'v_3']));
      });

      test('returns empty list when no verifications', () async {
        unawaited(
          mockTable(mockClient, 'partner_verified_users', selectData: []),
        );

        final result = await repository.getApprovedVerificationIds('user_1');

        expect(result, isEmpty);
      });

      test('returns empty list on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_verified_users',
            shouldThrow: Exception('db error'),
          ),
        );

        final result = await repository.getApprovedVerificationIds('user_1');

        expect(result, isEmpty);
      });

      test('filters out null verification IDs', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_verified_users',
            selectData: [
              {'verification_id': 'v_1'},
              {'verification_id': null},
              {'verification_id': 'v_3'},
            ],
          ),
        );

        final result = await repository.getApprovedVerificationIds('user_1');

        expect(result, hasLength(2));
        expect(result, containsAll(['v_1', 'v_3']));
      });
    });
  });
}
