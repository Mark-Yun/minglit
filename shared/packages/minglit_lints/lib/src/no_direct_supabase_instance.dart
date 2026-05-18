import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags direct access to `Supabase.instance.client` outside the allowed
/// Repository / provider locations.
///
/// All code that needs a `SupabaseClient` must obtain it via
/// `ref.watch(supabaseClientProvider)`. The singleton shortcut
/// `Supabase.instance.client` bypasses the DI graph and makes demo-flavor
/// overrides impossible.
///
/// ## Forbidden
/// ```dart
/// final client = Supabase.instance.client;
/// Supabase.instance.client.from('events').select();
/// Supabase.instance.client.auth.currentUser;
/// ```
///
/// ## Allowed
/// ```dart
/// // Inject via Riverpod — preferred everywhere
/// final client = ref.watch(supabaseClientProvider);
///
/// // Repository constructors may keep the fallback for legacy/test compat
/// // (path: **/data/repositories/**)
/// MyRepo({SupabaseClient? client})
///     : _client = client ?? Supabase.instance.client;
/// ```
///
/// ## Exempt paths (no warning emitted)
/// - `**/shared/packages/minglit_kit/lib/src/data/repositories/**`
/// - `**/shared/packages/minglit_kit/lib/src/logic/providers/supabase_provider.dart`
/// - `**/shared/packages/minglit_kit/lib/src/features/dev/**`
/// - `**/test/**`, `**/integration_test/**`, `**/patrol_test/**`
///
/// See: docs/infra/app_demo/architecture.md — "Dependency Rules"
class NoDirectSupabaseInstanceRule extends DartLintRule {
  const NoDirectSupabaseInstanceRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'minglit_no_direct_supabase_instance',
    problemMessage:
        'Direct access to Supabase.instance.client is forbidden outside '
        'Repository providers. '
        'Inject SupabaseClient via ref.watch(supabaseClientProvider) instead. '
        'See docs/infra/app_demo/architecture.md.',
    correctionMessage:
        'Replace Supabase.instance.client with '
        'ref.watch(supabaseClientProvider).',
  );

  /// Returns true when [filePath] is in an exempt location.
  ///
  /// Exposed as static for unit testing.
  static bool isExemptPath(String filePath) {
    // Normalise Windows-style separators just in case.
    final path = filePath.replaceAll(r'\', '/');

    // Repository implementations — constructor fallback allowed.
    if (_containsSegments(path, [
      'shared/packages/minglit_kit/lib/src/data/repositories/',
    ])) {
      return true;
    }

    // The provider file that wraps Supabase.instance by design.
    if (path.contains(
      'shared/packages/minglit_kit/lib/src/logic/providers/supabase_provider.dart',
    )) {
      return true;
    }

    // Dev-only screens — never shipped in demo/prod.
    if (_containsSegments(path, [
      'shared/packages/minglit_kit/lib/src/features/dev/',
    ])) {
      return true;
    }

    // Test code — may use the singleton directly.
    if (path.contains('/test/') ||
        path.contains('/integration_test/') ||
        path.contains('/patrol_test/')) {
      return true;
    }

    return false;
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (isExemptPath(resolver.path)) return;

    // Detect property access chains that contain `Supabase.instance.client`.
    //
    // A chain like `Supabase.instance.client.auth` is represented in the AST
    // as nested PropertyAccess nodes:
    //
    //   PropertyAccess(
    //     target: PropertyAccess(          ← Supabase.instance.client
    //       target: PropertyAccess(        ← Supabase.instance
    //         target: SimpleIdentifier("Supabase"),
    //         propertyName: "instance",
    //       ),
    //       propertyName: "client",
    //     ),
    //     propertyName: "auth",
    //   )
    //
    // We report on the *innermost* `client` access so that the squiggle
    // highlights the canonical violation point regardless of how many further
    // accesses are chained on top of it.
    context.registry.addPropertyAccess((node) {
      // We only care about nodes whose property is "client".
      if (node.propertyName.name != 'client') return;

      final target = node.target;
      if (target == null || !_isSupabaseInstanceAccess(target)) return;

      reporter.atNode(node.propertyName, _code);
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns true if [node] represents the expression `Supabase.instance`.
  static bool _isSupabaseInstanceAccess(Expression node) {
    if (node is! PropertyAccess) return false;
    if (node.propertyName.name != 'instance') return false;

    final target = node.target;
    if (target is! SimpleIdentifier) return false;
    return target.name == 'Supabase';
  }

  /// Returns true when [path] contains any of the given [segments].
  static bool _containsSegments(String path, List<String> segments) =>
      segments.any(path.contains);
}
