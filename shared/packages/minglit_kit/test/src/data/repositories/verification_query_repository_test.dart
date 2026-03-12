import 'dart:async' show unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/data/repositories/verification_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late SupabaseVerificationRepository repository;

  final now = DateTime.now();

  setUp(() {
    mockClient = createMockSupabase();
    repository = SupabaseVerificationRepository(supabase: mockClient);
  });

  group('VerificationRepository', () {
    group('getVerificationsByIds', () {
      test('returns empty list when ids is empty', () async {
        final result = await repository.getVerificationsByIds([]);
        expect(result, isEmpty);
      });

      test('returns parsed Verification list for valid JSON', () async {
        final verificationJson = {
          'id': 'ver_1',
          'category': 'career',
          'internal_name': 'global_career',
          'display_name': '직장 인증',
          'partner_id': null,
          'description': 'Career verification',
          'icon_key': 'briefcase',
          'form_schema': <Map<String, dynamic>>[],
          'is_active': true,
          'created_at': now.toIso8601String(),
        };

        unawaited(
          mockTable(
            mockClient,
            'verifications',
            selectData: [verificationJson],
          ),
        );

        final result = await repository.getVerificationsByIds(['ver_1']);

        expect(result, hasLength(1));
        expect(result.first.id, 'ver_1');
        expect(result.first.internalName, 'global_career');
        expect(result.first.displayName, '직장 인증');
      });

      test(
        'returns partial results and logs warning on TypeError (null field)',
        () async {
          // Simulate a record with null internal_name that will cause TypeError
          final validJson = {
            'id': 'ver_1',
            'category': 'career',
            'internal_name': 'global_career',
            'display_name': '직장 인증',
            'partner_id': null,
            'description': 'Career verification',
            'icon_key': 'briefcase',
            'form_schema': <Map<String, dynamic>>[],
            'is_active': true,
            'created_at': now.toIso8601String(),
          };

          final invalidJson = {
            'id': 'ver_2',
            'category': 'asset',
            'internal_name': null, // This will cause TypeError in fromJson
            'display_name': '자산 인증',
            'partner_id': null,
            'description': 'Asset verification',
            'icon_key': 'money',
            'form_schema': <Map<String, dynamic>>[],
            'is_active': true,
            'created_at': now.toIso8601String(),
          };

          unawaited(
            mockTable(
              mockClient,
              'verifications',
              selectData: [validJson, invalidJson],
            ),
          );

          // Should not throw, should return partial results
          final result = await repository.getVerificationsByIds([
            'ver_1',
            'ver_2',
          ]);

          // Should have parsed the first valid record
          expect(result, hasLength(1));
          expect(result.first.id, 'ver_1');
        },
      );

      test('rethrows non-TypeError/FormatException errors', () async {
        unawaited(
          mockTable(
            mockClient,
            'verifications',
            shouldThrow: Exception('Network error'),
          ),
        );

        expect(
          () => repository.getVerificationsByIds(['ver_1']),
          throwsException,
        );
      });
    });

  group('getPartnerVerifications', () {
    final verificationJson = {
      'id': 'ver_1',
      'category': 'career',
      'internal_name': 'global_career',
      'display_name': '직장 인증',
      'partner_id': 'partner_1',
      'description': 'Career verification',
      'icon_key': 'briefcase',
      'form_schema': <Map<String, dynamic>>[],
      'is_active': true,
      'created_at': now.toIso8601String(),
    };

    test('returns list of verifications for partner', () async {
      unawaited(
        mockTable(mockClient, 'verifications', selectData: [verificationJson]),
      );

      final result = await repository.getPartnerVerifications('partner_1');

      expect(result, hasLength(1));
      expect(result.first.id, 'ver_1');
    });

    test('returns empty list when no verifications', () async {
      unawaited(mockTable(mockClient, 'verifications', selectData: []));

      final result = await repository.getPartnerVerifications('partner_1');

      expect(result, isEmpty);
    });

    test('throws on error', () async {
      unawaited(
        mockTable(mockClient, 'verifications', shouldThrow: Exception('error')),
      );

      await expectLater(
        repository.getPartnerVerifications('partner_1'),
        throwsA(anything),
      );
    });
  });

  group('getGlobalVerifications', () {
    final globalVerJson = {
      'id': 'ver_global',
      'category': 'career',
      'internal_name': 'global_career',
      'display_name': '직장 인증',
      'partner_id': null,
      'description': 'Global career verification',
      'icon_key': 'briefcase',
      'form_schema': <Map<String, dynamic>>[],
      'is_active': true,
      'created_at': now.toIso8601String(),
    };

    test('returns list of global verifications', () async {
      unawaited(
        mockTable(mockClient, 'verifications', selectData: [globalVerJson]),
      );

      final result = await repository.getGlobalVerifications();

      expect(result, hasLength(1));
      expect(result.first.id, 'ver_global');
    });

    test('returns empty list when no global verifications', () async {
      unawaited(mockTable(mockClient, 'verifications', selectData: []));

      final result = await repository.getGlobalVerifications();

      expect(result, isEmpty);
    });

    test('throws on error', () async {
      unawaited(
        mockTable(mockClient, 'verifications', shouldThrow: Exception('error')),
      );

      await expectLater(
        repository.getGlobalVerifications(),
        throwsA(anything),
      );
    });
  });

  group('getVerificationById', () {
    final verJson = {
      'id': 'ver_1',
      'category': 'career',
      'internal_name': 'global_career',
      'display_name': '직장 인증',
      'partner_id': null,
      'description': 'Career verification',
      'icon_key': 'briefcase',
      'form_schema': <Map<String, dynamic>>[],
      'is_active': true,
      'created_at': now.toIso8601String(),
    };

    test('returns verification when found', () async {
      unawaited(
        mockTable(mockClient, 'verifications', maybeSingleData: verJson),
      );

      final result = await repository.getVerificationById('ver_1');

      expect(result, isNotNull);
      expect(result!.id, 'ver_1');
    });

    test('returns null when not found', () async {
      unawaited(mockTable(mockClient, 'verifications'));

      final result = await repository.getVerificationById('unknown');

      expect(result, isNull);
    });

    test('throws on error', () async {
      unawaited(
        mockTable(mockClient, 'verifications', shouldThrow: Exception('error')),
      );

      await expectLater(
        repository.getVerificationById('ver_1'),
        throwsA(anything),
      );
    });
  });

  group('getVerificationComments', () {
    test('returns list of comments', () async {
      final commentJson = {
        'id': 'comment_1',
        'submission_id': 'sub_1',
        'content': '수정 필요',
        'created_at': now.toIso8601String(),
      };
      unawaited(
        mockTable(
          mockClient,
          'verification_comments',
          selectData: [commentJson],
        ),
      );

      final result = await repository.getVerificationComments('sub_1');

      expect(result, hasLength(1));
      expect(result.first['id'], 'comment_1');
    });

    test('returns empty list when no comments', () async {
      unawaited(
        mockTable(mockClient, 'verification_comments', selectData: []),
      );

      final result = await repository.getVerificationComments('sub_1');

      expect(result, isEmpty);
    });

    test('throws on error', () async {
      unawaited(
        mockTable(
          mockClient,
          'verification_comments',
          shouldThrow: Exception('error'),
        ),
      );

      await expectLater(
        repository.getVerificationComments('sub_1'),
        throwsA(anything),
      );
    });
  });

  group('getRequestsByStatus', () {
    test('returns empty list when user not authenticated', () async {
      // mockClient already has no currentUser (createMockSupabase() with no args)
      final result = await repository.getRequestsByStatus(VerificationStatus.pending);
      expect(result, isEmpty);
    });

    test('returns list of requests for authenticated user', () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user_1');
      final authedClient = createMockSupabase(currentUser: mockUser);
      final authedRepo = SupabaseVerificationRepository(supabase: authedClient);

      unawaited(
        mockTable(authedClient, 'verification_submissions', selectData: [
          {'id': 'sub_1', 'status': 'pending', 'user_id': 'user_1'},
        ]),
      );

      final result = await authedRepo.getRequestsByStatus(VerificationStatus.pending);
      expect(result, hasLength(1));
      expect(result.first['id'], 'sub_1');
    });

    test('throws on error', () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user_1');
      final authedClient = createMockSupabase(currentUser: mockUser);
      final authedRepo = SupabaseVerificationRepository(supabase: authedClient);

      unawaited(
        mockTable(authedClient, 'verification_submissions', shouldThrow: Exception('error')),
      );

      await expectLater(
        authedRepo.getRequestsByStatus(VerificationStatus.pending),
        throwsA(anything),
      );
    });
  });
});
}
