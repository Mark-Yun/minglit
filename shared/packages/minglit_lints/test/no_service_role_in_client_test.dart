import 'package:minglit_lints/src/no_service_role_in_client_rule.dart';
import 'package:test/test.dart';

void main() {
  group('NoServiceRoleInClientRule.shouldLintPath', () {
    group('client lib paths: warning enabled', () {
      test('app_user lib', () {
        expect(
          NoServiceRoleInClientRule.shouldLintPath(
            '/repo/apps/app_user/lib/src/bootstrap/user_startup.dart',
          ),
          isTrue,
        );
      });

      test('app_partner lib', () {
        expect(
          NoServiceRoleInClientRule.shouldLintPath(
            '/repo/apps/app_partner/lib/src/bootstrap/partner_startup.dart',
          ),
          isTrue,
        );
      });

      test('minglit_kit lib', () {
        expect(
          NoServiceRoleInClientRule.shouldLintPath(
            '/repo/shared/packages/minglit_kit/lib/src/config/env_keystore.dart',
          ),
          isTrue,
        );
      });
    });

    group('server-only and non-client paths: warning disabled', () {
      test('Edge Function', () {
        expect(
          NoServiceRoleInClientRule.shouldLintPath(
            '/repo/supabase/functions/payment-verify/index.ts',
          ),
          isFalse,
        );
      });

      test('migration SQL', () {
        expect(
          NoServiceRoleInClientRule.shouldLintPath(
            '/repo/supabase/migrations/20260603000000_hardening.sql',
          ),
          isFalse,
        );
      });

      test('docs mention secret names intentionally', () {
        expect(
          NoServiceRoleInClientRule.shouldLintPath(
            '/repo/docs/architecture/edge-function-auth.md',
          ),
          isFalse,
        );
      });

      test('app test file', () {
        expect(
          NoServiceRoleInClientRule.shouldLintPath(
            '/repo/apps/app_user/test/src/config/env_keystore_test.dart',
          ),
          isFalse,
        );
      });
    });
  });

  group('NoServiceRoleInClientRule.isDangerousIdentifier', () {
    group('positive: elevated credential identifiers', () {
      test('serviceRoleKey', () {
        expect(
          NoServiceRoleInClientRule.isDangerousIdentifier('serviceRoleKey'),
          isTrue,
        );
      });

      test('SUPABASE_SERVICE_ROLE_KEY', () {
        expect(
          NoServiceRoleInClientRule.isDangerousIdentifier(
            'SUPABASE_SERVICE_ROLE_KEY',
          ),
          isTrue,
        );
      });

      test('supabaseSecretKeys', () {
        expect(
          NoServiceRoleInClientRule.isDangerousIdentifier('supabaseSecretKeys'),
          isTrue,
        );
      });

      test('sbSecret', () {
        expect(
          NoServiceRoleInClientRule.isDangerousIdentifier('sbSecret'),
          isTrue,
        );
      });
    });

    group('negative: public/client identifiers', () {
      test('supabasePublishableKey', () {
        expect(
          NoServiceRoleInClientRule.isDangerousIdentifier(
            'supabasePublishableKey',
          ),
          isFalse,
        );
      });

      test('statsigClientKey', () {
        expect(
          NoServiceRoleInClientRule.isDangerousIdentifier('statsigClientKey'),
          isFalse,
        );
      });

      test('kakaoMapJavascriptKey', () {
        expect(
          NoServiceRoleInClientRule.isDangerousIdentifier(
            'kakaoMapJavascriptKey',
          ),
          isFalse,
        );
      });
    });
  });

  group('NoServiceRoleInClientRule.isDangerousStringValue', () {
    group('positive: elevated credential string values', () {
      test('service-role env name', () {
        expect(
          NoServiceRoleInClientRule.isDangerousStringValue(
            'SUPABASE_SERVICE_ROLE_KEY',
          ),
          isTrue,
        );
      });

      test('secret key env name', () {
        expect(
          NoServiceRoleInClientRule.isDangerousStringValue(
            'SUPABASE_DEV_SECRET_KEY',
          ),
          isTrue,
        );
      });

      test('sb_secret literal', () {
        expect(
          NoServiceRoleInClientRule.isDangerousStringValue(
            'sb_secret_example123',
          ),
          isTrue,
        );
      });

      test('role literal', () {
        expect(
          NoServiceRoleInClientRule.isDangerousStringValue('service_role'),
          isTrue,
        );
      });
    });

    group('negative: safe public/client string values', () {
      test('publishable key env name', () {
        expect(
          NoServiceRoleInClientRule.isDangerousStringValue(
            'SUPABASE_PUBLISHABLE_KEY',
          ),
          isFalse,
        );
      });

      test('Statsig client key env name', () {
        expect(
          NoServiceRoleInClientRule.isDangerousStringValue(
            'STATSIG_CLIENT_KEY',
          ),
          isFalse,
        );
      });

      test('Kakao map JavaScript key env name', () {
        expect(
          NoServiceRoleInClientRule.isDangerousStringValue(
            'KAKAO_MAP_JAVASCRIPT_KEY',
          ),
          isFalse,
        );
      });

      test('ordinary role text', () {
        expect(
          NoServiceRoleInClientRule.isDangerousStringValue('partner_role'),
          isFalse,
        );
      });
    });
  });
}
