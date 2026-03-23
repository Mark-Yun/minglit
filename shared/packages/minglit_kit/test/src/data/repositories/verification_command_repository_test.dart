import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/data/repositories/verification_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockUser mockUser;
  late MockFunctionsClient mockFunctions;
  late SupabaseVerificationRepository repository;

  const verification = Verification(
    id: 'ver_1',
    category: VerificationCategory.career,
    internalName: 'global_career',
    displayName: '직장 인증',
    partnerId: 'partner_1',
    description: 'Career verification',
    iconKey: 'briefcase',
  );

  setUp(() {
    mockUser = MockUser();
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = SupabaseVerificationRepository(supabase: mockClient);
  });

  group('VerificationRepository (command)', () {
    // Fix #308: createVerification via EF
    group('createVerification', () {
      test('calls partner-manage-verification EF and returns result', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true, 'id': 'new-ver-id'},
          ),
        );

        final result = await repository.createVerification(verification);

        expect(result.id, 'new-ver-id');
        expect(result.displayName, '직장 인증');

        verify(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).called(1);
      });

      test('throws MinglitUserException on error response', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 403,
            data: {'error': 'Forbidden: insufficient partner permissions'},
          ),
        );

        expect(
          () => repository.createVerification(verification),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws on network error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

        await expectLater(
          repository.createVerification(verification),
          throwsA(anything),
        );
      });
    });

    // Fix #308: updateVerification via EF
    group('updateVerification', () {
      test('calls partner-manage-verification EF with update action', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true},
          ),
        );

        await expectLater(
          repository.updateVerification(verification),
          completes,
        );

        verify(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).called(1);
      });

      test('throws MinglitUserException on error response', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 403,
            data: {'error': 'Forbidden'},
          ),
        );

        expect(
          () => repository.updateVerification(verification),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws on network error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

        await expectLater(
          repository.updateVerification(verification),
          throwsA(anything),
        );
      });
    });

    // Fix #308: deleteVerification via EF (soft delete)
    group('deleteVerification', () {
      test('calls EF with update action and is_active=false', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true},
          ),
        );

        await expectLater(
          repository.deleteVerification('ver_1'),
          completes,
        );

        verify(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: {
              'action': 'update',
              'verification_id': 'ver_1',
              'is_active': false,
            },
          ),
        ).called(1);
      });

      test('throws MinglitUserException on error response', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 404,
            data: {'error': 'Verification not found'},
          ),
        );

        expect(
          () => repository.deleteVerification('ver_1'),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws on network error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

        await expectLater(
          repository.deleteVerification('ver_1'),
          throwsA(anything),
        );
      });
    });

    // Fix #308: restoreVerification via EF
    group('restoreVerification', () {
      test('calls EF with update action and is_active=true', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true},
          ),
        );

        await expectLater(
          repository.restoreVerification('ver_1'),
          completes,
        );

        verify(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: {
              'action': 'update',
              'verification_id': 'ver_1',
              'is_active': true,
            },
          ),
        ).called(1);
      });

      test('throws MinglitUserException on error response', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 403,
            data: {'error': 'Forbidden'},
          ),
        );

        expect(
          () => repository.restoreVerification('ver_1'),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws on network error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-verification',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

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
