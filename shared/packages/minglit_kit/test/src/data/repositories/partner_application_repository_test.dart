import 'dart:async' show unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/partner_application.dart';
import 'package:minglit_kit/src/data/repositories/partner_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late PartnerRepository repository;

  final now = DateTime.now();
  final mockUser = MockUser();

  final applicationJson = {
    'id': 'app_1',
    'user_id': 'user_1',
    'status': 'pending',
    'brand_name': 'Test Brand',
    'biz_name': 'Test Biz Co.',
    'biz_type': 'individual',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = PartnerRepository(supabase: mockClient);
  });

  group('PartnerApplicationRepository', () {
    group('getMyApplication', () {
      test('returns null when no application exists', () async {
        unawaited(mockTable(mockClient, 'partner_applications'));

        final result = await repository.getMyApplication();
        expect(result, isNull);
      });

      test('returns application when data exists', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            maybeSingleData: applicationJson,
          ),
        );

        final result = await repository.getMyApplication();
        expect(result, isNotNull);
        expect(result!.id, 'app_1');
        expect(result.userId, 'user_1');
        expect(result.status, 'pending');
      });

      test('returns null when user not logged in', () async {
        mockClient = createMockSupabase(); // no user
        repository = PartnerRepository(supabase: mockClient);

        final result = await repository.getMyApplication();
        expect(result, isNull);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            shouldThrow: Exception('network error'),
          ),
        );

        await expectLater(
          repository.getMyApplication(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getAllApplications', () {
      test('returns list of applications', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            selectData: [applicationJson],
          ),
        );

        final result = await repository.getAllApplications();
        expect(result, hasLength(1));
        expect(result.first.id, 'app_1');
        expect(result.first.brandName, 'Test Brand');
      });

      test('returns empty list when no applications', () async {
        unawaited(
          mockTable(mockClient, 'partner_applications', selectData: []),
        );

        final result = await repository.getAllApplications();
        expect(result, isEmpty);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            shouldThrow: Exception('db error'),
          ),
        );

        await expectLater(
          repository.getAllApplications(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('reviewApplication', () {
      test('completes successfully', () async {
        unawaited(mockTable(mockClient, 'partner_applications'));

        await expectLater(
          repository.reviewApplication(
            applicationId: 'app_1',
            status: 'approved',
            adminComment: 'Looks good',
          ),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            shouldThrow: Exception('review failed'),
          ),
        );

        await expectLater(
          repository.reviewApplication(
            applicationId: 'app_1',
            status: 'rejected',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    // Fix #311: saveDraft via EF
    group('saveDraft', () {
      test('inserts new draft when id is empty', () async {
        const draftApp = PartnerApplication(
          id: '',
          userId: 'user_1',
          brandName: 'New Brand',
        );

        when(
          () => mockFunctions.invoke(
            'partner-register',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true, 'application_id': 'app_1'},
          ),
        );

        // Re-fetch after EF
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            singleData: applicationJson,
          ),
        );

        final result = await repository.saveDraft(draftApp);
        expect(result.id, 'app_1');
        expect(result.userId, 'user_1');
      });

      test('updates existing draft when id is non-empty', () async {
        const existingApp = PartnerApplication(
          id: 'app_1',
          userId: 'user_1',
          brandName: 'Existing Brand',
        );

        when(
          () => mockFunctions.invoke(
            'partner-register',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true, 'application_id': 'app_1'},
          ),
        );

        // Re-fetch after EF
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            singleData: applicationJson,
          ),
        );

        final result = await repository.saveDraft(existingApp);
        expect(result.id, 'app_1');
      });

      test('throws when user not logged in', () async {
        mockClient = createMockSupabase(); // no user
        repository = PartnerRepository(supabase: mockClient);

        const draftApp = PartnerApplication(
          id: '',
          userId: 'user_1',
        );

        await expectLater(
          repository.saveDraft(draftApp),
          throwsA(isA<Exception>()),
        );
      });

      test('throws MinglitUserException on EF error', () async {
        const draftApp = PartnerApplication(
          id: '',
          userId: 'user_1',
        );

        when(
          () => mockFunctions.invoke(
            'partner-register',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 403,
            data: {'error': 'Forbidden: not your application'},
          ),
        );

        await expectLater(
          repository.saveDraft(draftApp),
          throwsA(isA<MinglitUserException>()),
        );
      });
    });

    // Fix #311: updateApplication via EF
    group('updateApplication', () {
      test('returns updated application on success', () async {
        const app = PartnerApplication(
          id: 'app_1',
          userId: 'user_1',
          brandName: 'Updated Brand',
        );

        when(
          () => mockFunctions.invoke(
            'partner-register',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true, 'application_id': 'app_1'},
          ),
        );

        // Re-fetch after EF
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            singleData: applicationJson,
          ),
        );

        final result = await repository.updateApplication(app);
        expect(result.id, 'app_1');
      });

      test('throws on error', () async {
        const app = PartnerApplication(
          id: 'app_1',
          userId: 'user_1',
        );

        when(
          () => mockFunctions.invoke(
            'partner-register',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: {'error': 'Application cannot be updated in current status'},
          ),
        );

        await expectLater(
          repository.updateApplication(app),
          throwsA(isA<MinglitUserException>()),
        );
      });
    });

    // Fix #311: submitDraft via EF (서버 사이드 검증)
    group('submitDraft', () {
      test('returns submitted application on success', () async {
        final pendingJson = {...applicationJson, 'status': 'pending'};

        when(
          () => mockFunctions.invoke(
            'partner-register',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true},
          ),
        );

        // Re-fetch after EF
        unawaited(
          mockTable(
            mockClient,
            'partner_applications',
            singleData: pendingJson,
          ),
        );

        final result = await repository.submitDraft(applicationId: 'app_1');
        expect(result.id, 'app_1');
        expect(result.status, 'pending');
      });

      test('throws on error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-register',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: {'error': 'validation_failed'},
          ),
        );

        await expectLater(
          repository.submitDraft(applicationId: 'app_1'),
          throwsA(isA<MinglitUserException>()),
        );
      });
    });
  });
}
