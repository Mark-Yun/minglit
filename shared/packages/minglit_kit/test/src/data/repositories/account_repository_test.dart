import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/withdrawal_reason.dart';
import 'package:minglit_kit/src/data/repositories/account_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockFunctionsClient mockFunctions;
  late MockUser mockUser;
  late AccountRepository repository;

  setUp(() {
    mockUser = MockUser();
    mockClient = createMockSupabase(currentUser: mockUser);
    mockAuth = mockClient.auth as MockGoTrueClient;
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = AccountRepository(mockClient);

    when(() => mockUser.id).thenReturn('user_1');
    when(() => mockUser.email).thenReturn('user@example.com');
    when(() => mockUser.identities).thenReturn(const []);
    when(() => mockUser.appMetadata).thenReturn(const {});
  });

  group('AccountRepository', () {
    group('deleteAccount', () {
      test('sends anonymous reason and returns pending status', () async {
        when(
          () => mockFunctions.invoke(
            'user-delete-account',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'grace_period_ends': '2026-04-06T00:00:00Z',
            },
          ),
        );

        final result = await repository.deleteAccount(
          const WithdrawalReason(
            reasonCode: WithdrawalReasonCode.privacyConcern,
            detail: 'privacy',
          ),
        );

        final captured =
            verify(
                  () => mockFunctions.invoke(
                    'user-delete-account',
                    body: captureAny(named: 'body'),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['reason_code'], 'privacy_concern');
        expect(captured['reason_text'], 'privacy');
        expect(result.isPending, true);
        expect(result.gracePeriodEnds, DateTime.parse('2026-04-06T00:00:00Z'));
      });

      test('omits reason fields when no reason was selected', () async {
        when(
          () => mockFunctions.invoke(
            'user-delete-account',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'grace_period_ends': '2026-04-06T00:00:00Z',
            },
          ),
        );

        await repository.deleteAccount(null);

        final captured =
            verify(
                  () => mockFunctions.invoke(
                    'user-delete-account',
                    body: captureAny(named: 'body'),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured, isEmpty);
      });

      test('throws MinglitUserException on EF error', () async {
        when(
          () => mockFunctions.invoke(
            'user-delete-account',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 409,
            data: {'error': 'Account deletion already pending'},
          ),
        );

        await expectLater(
          () => repository.deleteAccount(null),
          throwsA(
            isA<MinglitUserException>().having(
              (e) => e.message,
              'message',
              'Account deletion already pending',
            ),
          ),
        );
      });
    });

    group('cancelDeletion', () {
      test('calls the cancel edge function', () async {
        when(
          () => mockFunctions.invoke('user-cancel-deletion'),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'success': true}),
        );

        await repository.cancelDeletion();

        verify(() => mockFunctions.invoke('user-cancel-deletion')).called(1);
      });
    });

    group('getDeletionStatus', () {
      test('returns pending status when deleted_at exists', () async {
        unawaited(
          mockTable(
            mockClient,
            'user_profiles',
            maybeSingleData: {'deleted_at': '2026-03-30T00:00:00Z'},
          ),
        );

        final result = await repository.getDeletionStatus();

        expect(result, isNotNull);
        expect(result!.isPending, true);
        expect(result.deletedAt, DateTime.parse('2026-03-30T00:00:00Z'));
        expect(result.gracePeriodEnds, DateTime.parse('2026-04-06T00:00:00Z'));
      });

      test('returns non-pending status when deleted_at is null', () async {
        unawaited(
          mockTable(
            mockClient,
            'user_profiles',
            maybeSingleData: {'deleted_at': null},
          ),
        );

        final result = await repository.getDeletionStatus();

        expect(result, isNotNull);
        expect(result!.isPending, false);
        expect(result.deletedAt, isNull);
        expect(result.gracePeriodEnds, isNull);
      });
    });

    group('reauthenticate', () {
      test('uses password sign-in when has_password flag is true', () async {
        when(
          () => mockUser.appMetadata,
        ).thenReturn(const {'has_password': true});
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        await repository.reauthenticate('pw-1234');

        verify(
          () => mockAuth.signInWithPassword(
            email: 'user@example.com',
            password: 'pw-1234',
          ),
        ).called(1);
        verifyNever(() => mockAuth.reauthenticate());
      });

      test(
        'uses password sign-in when has_password flag is string true',
        () async {
          when(
            () => mockUser.appMetadata,
          ).thenReturn(const {'has_password': 'TRUE'});
          when(
            () => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => AuthResponse());

          await repository.reauthenticate('pw-1234');

          verify(
            () => mockAuth.signInWithPassword(
              email: 'user@example.com',
              password: 'pw-1234',
            ),
          ).called(1);
          verifyNever(() => mockAuth.reauthenticate());
        },
      );

      test('throws when password-backed user password is missing', () async {
        when(
          () => mockUser.appMetadata,
        ).thenReturn(const {'has_password': true});

        await expectLater(
          () => repository.reauthenticate(null),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test(
        'uses Supabase reauthenticate when has_password flag is false',
        () async {
          when(
            () => mockUser.appMetadata,
          ).thenReturn(const {'has_password': false});
          when(() => mockAuth.reauthenticate()).thenAnswer((_) async {});

          await repository.reauthenticate(null);

          verify(() => mockAuth.reauthenticate()).called(1);
          verifyNever(
            () => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          );
        },
      );

      test(
        'uses Supabase reauthenticate when has_password flag is string false',
        () async {
          when(
            () => mockUser.appMetadata,
          ).thenReturn(const {'has_password': 'false'});
          when(() => mockAuth.reauthenticate()).thenAnswer((_) async {});

          await repository.reauthenticate(null);

          verify(() => mockAuth.reauthenticate()).called(1);
          verifyNever(
            () => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          );
        },
      );

      test(
        'defaults to Supabase reauthenticate when password flag is absent',
        () async {
          when(() => mockAuth.reauthenticate()).thenAnswer((_) async {});

          await repository.reauthenticate(null);

          verify(() => mockAuth.reauthenticate()).called(1);
          verifyNever(
            () => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          );
        },
      );
    });
  });
}
