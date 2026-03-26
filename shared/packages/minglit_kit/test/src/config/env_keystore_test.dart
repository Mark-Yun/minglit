import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/config/env_keystore.dart';

/// Tests for [EnvKeyStore].
///
/// In the test environment no `--dart-define` flags are passed, so every
/// `String.fromEnvironment` resolves to `''`.  This lets us exercise the
/// "missing" paths without any special setup.
void main() {
  group('EnvKeyStore', () {
    group('missingRequired', () {
      test('returns all required keys when none are defined', () {
        final missing = EnvKeyStore.missingRequired();

        expect(missing, contains('SUPABASE_URL'));
        expect(missing, contains('SUPABASE_PUBLISHABLE_KEY'));
        expect(missing, contains('ENVIRONMENT'));
        expect(missing, hasLength(3));
      });
    });

    group('missingOptional', () {
      test('returns all optional keys when none are defined', () {
        final missing = EnvKeyStore.missingOptional();

        expect(missing, containsAll(['SENTRY_DSN']));
        expect(missing, containsAll(['STATSIG_CLIENT_KEY']));
        expect(missing, containsAll(['GOOGLE_WEB_CLIENT_ID']));
        expect(missing, containsAll(['KAKAO_LOCAL_REST_API_KEY']));
        expect(missing, containsAll(['KAKAO_MAP_JAVASCRIPT_KEY']));
        expect(missing, containsAll(['JUSO_CONFIRM_KEY']));
        expect(missing, containsAll(['IAMPORT_USER_CODE']));
        expect(missing, containsAll(['MOBILE_REDIRECT_SCHEME']));
        expect(missing, hasLength(8));
      });
    });

    group('validate', () {
      test('throws StateError when required env vars are missing', () {
        expect(
          EnvKeyStore.validate,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('missing required env vars'),
                contains('SUPABASE_URL'),
                contains('--dart-define-from-file'),
              ),
            ),
          ),
        );
      });

      test('error message includes all missing required keys', () {
        expect(
          EnvKeyStore.validate,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('SUPABASE_URL'),
                contains('SUPABASE_PUBLISHABLE_KEY'),
                contains('ENVIRONMENT'),
              ),
            ),
          ),
        );
      });
    });
  });
}
