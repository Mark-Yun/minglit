import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/staff_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

class MockUserResponse extends Mock implements UserResponse {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late StaffRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = createMockSupabase();
    mockAuth = mockClient.auth as MockGoTrueClient;
    repository = StaffRepository(
      supabase: mockClient,
      redirectUrl: 'https://example.com/callback/',
    );
  });

  group('StaffRepository', () {
    group('saveStaffToken', () {
      test('saves token to SharedPreferences', () async {
        await repository.saveStaffToken('test_jwt_token');

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('minglit_staff_proof_token'),
          'test_jwt_token',
        );
      });
    });

    group('clearStaffToken', () {
      test('removes token from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'minglit_staff_proof_token': 'existing_token',
        });

        await repository.clearStaffToken();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('minglit_staff_proof_token'), isNull);
      });
    });

    group('verifyStaffStatus', () {
      test('returns null when no token stored', () async {
        final result = await repository.verifyStaffStatus();
        expect(result, isNull);
      });

      test('returns user when token valid and email is @minglit.com', () async {
        SharedPreferences.setMockInitialValues({
          'minglit_staff_proof_token': 'valid_token',
        });

        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('staff_1');
        when(() => mockUser.email).thenReturn('admin@minglit.com');

        final mockResponse = MockUserResponse();
        when(() => mockResponse.user).thenReturn(mockUser);

        when(() => mockAuth.getUser('valid_token')).thenAnswer(
          (_) async => mockResponse,
        );

        final result = await repository.verifyStaffStatus();

        expect(result, isNotNull);
        expect(result!.email, 'admin@minglit.com');
      });

      test(
        'returns null and clears token when email is not @minglit.com',
        () async {
          SharedPreferences.setMockInitialValues({
            'minglit_staff_proof_token': 'valid_token',
          });

          final mockUser = MockUser();
          when(() => mockUser.email).thenReturn('user@gmail.com');

          final mockResponse = MockUserResponse();
          when(() => mockResponse.user).thenReturn(mockUser);

          when(() => mockAuth.getUser('valid_token')).thenAnswer(
            (_) async => mockResponse,
          );

          final result = await repository.verifyStaffStatus();

          expect(result, isNull);
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('minglit_staff_proof_token'), isNull);
        },
      );

      test('returns null and clears token when verification fails', () async {
        SharedPreferences.setMockInitialValues({
          'minglit_staff_proof_token': 'expired_token',
        });

        when(() => mockAuth.getUser('expired_token')).thenThrow(
          const AuthException('Token expired'),
        );

        final result = await repository.verifyStaffStatus();

        expect(result, isNull);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('minglit_staff_proof_token'), isNull);
      });
    });

    group('sendMagicLink', () {
      test('throws AuthException for non-minglit email', () async {
        await expectLater(
          repository.sendMagicLink('user@gmail.com'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('@minglit.com'),
            ),
          ),
        );
      });

      test('sends OTP for valid @minglit.com email', () async {
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        await expectLater(
          repository.sendMagicLink('admin@minglit.com'),
          completes,
        );

        verify(
          () => mockAuth.signInWithOtp(
            email: 'admin@minglit.com',
            emailRedirectTo: 'https://example.com/callback',
          ),
        ).called(1);
      });

      test('throws on auth error', () async {
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenThrow(const AuthException('Send failed'));

        await expectLater(
          repository.sendMagicLink('admin@minglit.com'),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
