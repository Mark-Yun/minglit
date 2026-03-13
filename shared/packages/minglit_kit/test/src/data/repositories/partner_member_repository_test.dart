import 'dart:async' show FutureOr, unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/partner_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

class _FakeRpcResult extends Fake implements PostgrestFilterBuilder<dynamic> {
  _FakeRpcResult(this._data);
  final dynamic _data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic) onValue, {
    Function? onError,
  }) {
    return Future<dynamic>.value(_data).then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late PartnerRepository repository;

  final now = DateTime.now();
  final mockUser = MockUser();

  final memberJson = {
    'user_id': 'user_1',
    'partner_id': 'partner_1',
    'role': 'member',
    'permissions': ['view'],
    'joined_at': now.toIso8601String(),
    'user_name': 'Test User',
    'user_profile_image': null,
  };

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    repository = PartnerRepository(supabase: mockClient);
  });

  group('PartnerMemberRepository', () {
    group('getPartnerMembers', () {
      test('returns list of members', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_partner_members_with_user',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => _FakeRpcResult([memberJson]));

        final result = await repository.getPartnerMembers('partner_1');

        expect(result, hasLength(1));
        final user = result.first['user'] as Map<String, dynamic>;
        expect(user['id'], 'user_1');
        expect(result.first['role'], 'member');
      });

      test('returns empty list when no members', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_partner_members_with_user',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => _FakeRpcResult(<dynamic>[]));

        final result = await repository.getPartnerMembers('partner_1');

        expect(result, isEmpty);
      });

      test('throws on rpc error', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_partner_members_with_user',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('rpc error'));

        await expectLater(
          repository.getPartnerMembers('partner_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateMemberRole', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'partner_member_permissions'));

        await expectLater(
          repository.updateMemberRole(
            partnerId: 'partner_1',
            userId: 'user_1',
            role: 'owner',
          ),
          completes,
        );
      });

      test('throws on db error', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_member_permissions',
            shouldThrow: Exception('db error'),
          ),
        );

        await expectLater(
          repository.updateMemberRole(
            partnerId: 'partner_1',
            userId: 'user_1',
            role: 'owner',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateMemberPermissions', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'partner_member_permissions'));

        await expectLater(
          repository.updateMemberPermissions(
            partnerId: 'partner_1',
            userId: 'user_1',
            permissions: ['view', 'edit'],
          ),
          completes,
        );
      });

      test('throws on db error', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_member_permissions',
            shouldThrow: Exception('permissions update failed'),
          ),
        );

        await expectLater(
          repository.updateMemberPermissions(
            partnerId: 'partner_1',
            userId: 'user_1',
            permissions: ['view'],
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
