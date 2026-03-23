import 'dart:async' show FutureOr;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/partner_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
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
  late MockFunctionsClient mockFunctions;

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
    mockFunctions = mockClient.functions as MockFunctionsClient;
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
      test('calls partner-manage-member EF with update_role action', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-member',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'success': true}),
        );

        await expectLater(
          repository.updateMemberRole(
            partnerId: 'partner_1',
            userId: 'user_1',
            role: 'manager',
          ),
          completes,
        );

        verify(
          () => mockFunctions.invoke(
            'partner-manage-member',
            body: {
              'action': 'update_role',
              'partner_id': 'partner_1',
              'user_id': 'user_1',
              'role': 'manager',
            },
          ),
        ).called(1);
      });

      test('throws MinglitUserException on non-200 response', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-member',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 403,
            data: {'error': 'Forbidden: insufficient partner permissions'},
          ),
        );

        await expectLater(
          repository.updateMemberRole(
            partnerId: 'partner_1',
            userId: 'user_1',
            role: 'owner',
          ),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws on network error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-member',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

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
      test(
        'calls partner-manage-member EF with update_permissions action',
        () async {
          when(
            () => mockFunctions.invoke(
              'partner-manage-member',
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => FunctionResponse(status: 200, data: {'success': true}),
          );

          await expectLater(
            repository.updateMemberPermissions(
              partnerId: 'partner_1',
              userId: 'user_1',
              permissions: ['PARTY_MANAGE', 'COMMENT_MANAGE'],
            ),
            completes,
          );

          verify(
            () => mockFunctions.invoke(
              'partner-manage-member',
              body: {
                'action': 'update_permissions',
                'partner_id': 'partner_1',
                'user_id': 'user_1',
                'permissions': ['PARTY_MANAGE', 'COMMENT_MANAGE'],
              },
            ),
          ).called(1);
        },
      );

      test('throws MinglitUserException on non-200 response', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-member',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: {'error': 'Invalid permission: HACK'},
          ),
        );

        await expectLater(
          repository.updateMemberPermissions(
            partnerId: 'partner_1',
            userId: 'user_1',
            permissions: ['HACK'],
          ),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws on network error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-member',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

        await expectLater(
          repository.updateMemberPermissions(
            partnerId: 'partner_1',
            userId: 'user_1',
            permissions: ['PARTY_MANAGE'],
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
