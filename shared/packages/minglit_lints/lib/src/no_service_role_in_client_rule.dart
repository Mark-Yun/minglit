import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags Supabase elevated-key exposure in Flutter/client Dart code.
///
/// Client code may use publishable/public keys only. Service-role JWTs and
/// `sb_secret_...` keys belong to Edge Functions, workflows, or server-only
/// tooling.
class NoServiceRoleInClientRule extends DartLintRule {
  const NoServiceRoleInClientRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'no_service_role_in_client',
    problemMessage:
        'Service-role or Supabase secret-key material is forbidden in client '
        'Dart code.',
    correctionMessage:
        'Keep elevated Supabase credentials in Edge Functions or CI/server '
        'tooling. Client code may only use publishable/public keys.',
  );

  static const _dangerousEnvNames = {
    'SUPABASE_SERVICE_ROLE_KEY',
    'SUPABASE_SECRET_KEYS',
    'SUPABASE_DEV_SECRET_KEY',
    'SUPABASE_MAIN_SECRET_KEY',
    'SERVICE_ROLE_KEY',
    'SERVICE_ROLE_JWT',
    'SB_SECRET_KEY',
  };

  static const _safePublicEnvNames = {
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
    'SUPABASE_ANON_KEY',
    'SENTRY_DSN',
    'STATSIG_CLIENT_KEY',
    'GOOGLE_WEB_CLIENT_ID',
    'KAKAO_LOCAL_REST_API_KEY',
    'KAKAO_MAP_JAVASCRIPT_KEY',
    'JUSO_CONFIRM_KEY',
    'IAMPORT_USER_CODE',
    'MOBILE_REDIRECT_SCHEME',
  };

  /// Returns true when [filePath] is a Flutter/client source location.
  ///
  /// Exposed as static for unit testing.
  static bool isClientPath(String filePath) {
    final path = _normalizePath(filePath);
    return path.startsWith('lib/') ||
        path.startsWith('package:app_user/') ||
        path.startsWith('package:app_partner/') ||
        path.startsWith('package:minglit_kit/') ||
        path.contains('apps/app_user/lib/') ||
        path.contains('apps/app_partner/lib/') ||
        path.contains('shared/packages/minglit_kit/lib/');
  }

  /// Returns true for paths where service-role terms can appear legitimately.
  ///
  /// Exposed as static for unit testing.
  static bool isExemptPath(String filePath) {
    final path = _normalizePath(filePath);
    return path.startsWith('test/') ||
        path.startsWith('integration_test/') ||
        path.startsWith('patrol_test/') ||
        path.contains('/test/') ||
        path.contains('/integration_test/') ||
        path.contains('/patrol_test/') ||
        path.contains('supabase/functions/') ||
        path.contains('supabase/migrations/') ||
        path.contains('.github/') ||
        path.contains('docs/') ||
        path.contains('scripts/');
  }

  /// Returns true when this lint should run for [filePath].
  ///
  /// Exposed as static for unit testing.
  static bool shouldLintPath(String filePath) =>
      isClientPath(filePath) && !isExemptPath(filePath);

  /// Returns true when [name] is a dangerous client identifier.
  ///
  /// Exposed as static for unit testing.
  static bool isDangerousIdentifier(String name) {
    final upper = name.toUpperCase();
    if (_dangerousEnvNames.contains(upper)) return true;

    final compact = name.replaceAll(RegExp('[^A-Za-z0-9]'), '').toLowerCase();

    return compact == 'servicerole' ||
        compact.contains('servicerolekey') ||
        compact.contains('supabaseservicerole') ||
        compact.contains('supabasesecretkey') ||
        compact.contains('supabasesecretkeys') ||
        compact.contains('sbsecret');
  }

  /// Returns true when [value] is a dangerous client string literal.
  ///
  /// Exposed as static for unit testing.
  static bool isDangerousStringValue(String value) {
    final trimmed = value.trim();
    final upper = trimmed.toUpperCase();
    if (_safePublicEnvNames.contains(upper)) return false;
    if (_dangerousEnvNames.contains(upper)) return true;

    final lower = trimmed.toLowerCase();
    return lower.contains('sb_secret_') || lower.contains('service_role');
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (!shouldLintPath(resolver.path)) return;

    void reportDangerousToken(Token? token) {
      if (token == null) return;
      if (!isDangerousIdentifier(token.lexeme)) return;
      reporter.atToken(token, _code);
    }

    context.registry.addVariableDeclaration((node) {
      reportDangerousToken(node.name);
    });

    context.registry.addFormalParameter((node) {
      reportDangerousToken(node.name);
    });

    context.registry.addSimpleIdentifier((node) {
      if (!isDangerousIdentifier(node.name)) return;
      reporter.atNode(node, _code);
    });

    context.registry.addSimpleStringLiteral((node) {
      final value = node.value;
      if (!isDangerousStringValue(value)) return;
      reporter.atNode(node, _code);
    });
  }

  static String _normalizePath(String filePath) =>
      filePath.replaceAll(r'\', '/');
}
