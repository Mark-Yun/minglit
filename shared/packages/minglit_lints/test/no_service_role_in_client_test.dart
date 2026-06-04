import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

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

      test('prefixed service role key identifier', () {
        expect(
          NoServiceRoleInClientRule.isDangerousIdentifier(
            'reviewCodexServiceRoleKey',
          ),
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

  group('NoServiceRoleInClientRule custom_lint integration', () {
    test(
      'dart run custom_lint flags app_user client fixtures',
      () async {
        final packageRoot = await _minglitLintsPackageRoot();
        final tempRoot = await Directory.systemTemp.createTemp(
          'minglit_lints_service_role_',
        );
        addTearDown(() {
          if (tempRoot.existsSync()) {
            tempRoot.deleteSync(recursive: true);
          }
        });

        final appDir = Directory('${tempRoot.path}/apps/app_user');
        await Directory('${appDir.path}/lib').create(recursive: true);

        await File('${appDir.path}/pubspec.yaml').writeAsString('''
name: app_user
publish_to: none

environment:
  sdk: ">=3.6.0 <4.0.0"

dev_dependencies:
  custom_lint: 0.8.1
  minglit_lints:
    path: ${packageRoot.path.replaceAll(r'\', '/')}
''');

        await File('${appDir.path}/analysis_options.yaml').writeAsString('''
analyzer:
  plugins:
    - custom_lint
''');

        await File('${appDir.path}/lib/main.dart').writeAsString('''
const reviewCodexServiceRoleKey = 'x';
const reviewCodexPublicKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const reviewCodexLeak =
    String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

void acceptsSecret(String sbSecret) {}
''');

        final pubGet = await Process.run(
          'dart',
          ['pub', 'get'],
          workingDirectory: appDir.path,
        );
        expect(
          pubGet.exitCode,
          0,
          reason: 'dart pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
        );

        final customLint = await Process.run(
          'dart',
          ['run', 'custom_lint', '--format=json'],
          workingDirectory: appDir.path,
        );
        expect(
          customLint.exitCode,
          isNot(0),
          reason: 'custom_lint should fail on service-role fixtures',
        );

        final output =
            jsonDecode(customLint.stdout as String) as Map<String, dynamic>;
        final diagnostics =
            (output['diagnostics'] as List).cast<Map<String, dynamic>>();
        final serviceRoleDiagnostics = diagnostics
            .where(
              (diagnostic) => diagnostic['code'] == 'no_service_role_in_client',
            )
            .toList();

        expect(serviceRoleDiagnostics, hasLength(greaterThanOrEqualTo(3)));
        expect(
          serviceRoleDiagnostics.map((diagnostic) {
            final location = diagnostic['location'] as Map;
            return location['file'] as String;
          }),
          everyElement(endsWith('apps/app_user/lib/main.dart')),
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

Future<Directory> _minglitLintsPackageRoot() async {
  final libUri = await Isolate.resolvePackageUri(
    Uri.parse('package:minglit_lints/minglit_lints.dart'),
  );
  if (libUri == null) {
    throw StateError('Unable to resolve package:minglit_lints');
  }
  return File.fromUri(libUri).parent.parent;
}
