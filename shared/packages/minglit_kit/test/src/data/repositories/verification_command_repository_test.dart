import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/data/repositories/verification_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockUser mockUser;
  late SupabaseVerificationRepository repository;

  final now = DateTime.now();

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

  setUp(() {
    mockUser = MockUser();
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    repository = SupabaseVerificationRepository(supabase: mockClient);
  });

  group('VerificationRepository (command)', () {
    group('createVerification', () {
      test('returns created verification on success', () async {
        unawaited(
          mockTable(
            mockClient,
            'verifications',
            singleData: verificationJson,
          ),
        );

        final verification = Verification.fromJson(verificationJson);
        final result = await repository.createVerification(verification);

        expect(result.id, 'ver_1');
        expect(result.displayName, '직장 인증');
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'verifications',
            shouldThrow: Exception('DB error'),
          ),
        );

        final verification = Verification.fromJson(verificationJson);
        await expectLater(
          repository.createVerification(verification),
          throwsA(anything),
        );
      });
    });

    group('updateVerification', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'verifications'));

        final verification = Verification.fromJson(verificationJson);
        await expectLater(
          repository.updateVerification(verification),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'verifications',
            shouldThrow: Exception('DB error'),
          ),
        );

        final verification = Verification.fromJson(verificationJson);
        await expectLater(
          repository.updateVerification(verification),
          throwsA(anything),
        );
      });
    });

    group('deleteVerification', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'verifications'));

        await expectLater(
          repository.deleteVerification('ver_1'),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'verifications',
            shouldThrow: Exception('DB error'),
          ),
        );

        await expectLater(
          repository.deleteVerification('ver_1'),
          throwsA(anything),
        );
      });
    });

    group('restoreVerification', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'verifications'));

        await expectLater(
          repository.restoreVerification('ver_1'),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'verifications',
            shouldThrow: Exception('DB error'),
          ),
        );

        await expectLater(
          repository.restoreVerification('ver_1'),
          throwsA(anything),
        );
      });
    });

    group('reviewRequest', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'verification_submissions'));

        await expectLater(
          repository.reviewRequest(
            submissionId: 'sub_1',
            status: VerificationStatus.approved,
          ),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'verification_submissions',
            shouldThrow: Exception('DB error'),
          ),
        );

        await expectLater(
          repository.reviewRequest(
            submissionId: 'sub_1',
            status: VerificationStatus.rejected,
          ),
          throwsA(anything),
        );
      });
    });
  });
}
