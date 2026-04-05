import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/config/env_keystore.dart';

/// Tests for [EnvKeyStore].
///
/// In the test environment no `--dart-define` flags are passed, so every
/// `String.fromEnvironment` without a `defaultValue` resolves to `''`.
/// ENVIRONMENT uses a sentinel ('__UNSET__') and defaults to 'dev' in
/// non-release builds (Fix #1070). Release-build guard is not exercised
/// here because dart.vm.product is false in test runs.
void main() {
  group('EnvKeyStore', () {
    group('missingRequired', () {
      test(
        'returns SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY when none are defined',
        () {
          final missing = EnvKeyStore.missingRequired();

          expect(missing, contains('SUPABASE_URL'));
          expect(missing, contains('SUPABASE_PUBLISHABLE_KEY'));
          expect(missing, hasLength(2));
        },
      );

      // Regression test for #1070: ENVIRONMENT uses sentinel + defaults to
      // 'dev' in non-release builds, so it must never appear in
      // missingRequired().
      test(
        'does not include ENVIRONMENT — sentinel defaults to dev in debug',
        () {
          final missing = EnvKeyStore.missingRequired();

          expect(missing, isNot(contains('ENVIRONMENT')));
        },
      );
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
              ),
            ),
          ),
        );
      });

      // Regression test for #1070: in debug/test builds, validate() must not
      // throw about ENVIRONMENT (sentinel resolves to 'dev').
      // The release-build guard (dart.vm.product) is not active here.
      test(
        'error message does not include ENVIRONMENT in debug builds',
        () {
          expect(
            EnvKeyStore.validate,
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                isNot(contains('ENVIRONMENT')),
              ),
            ),
          );
        },
      );
    });
  });
}
