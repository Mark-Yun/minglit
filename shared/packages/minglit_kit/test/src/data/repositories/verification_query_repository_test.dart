import 'dart:async' show unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/verification_repository.dart';

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
  });
}
