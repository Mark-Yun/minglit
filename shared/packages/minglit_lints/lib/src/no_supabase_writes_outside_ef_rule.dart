import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags direct Supabase write operations (insert/update/delete/upsert) in
/// Flutter app code. All writes must go through Edge Functions (EF).
///
/// ## Forbidden
/// ```dart
/// supabase.from('events').insert({'name': 'Party'});
/// supabase.from('tickets').update({'status': 'sold'}).eq('id', id);
/// client.from('orders').delete().match({'user_id': uid});
/// ```
///
/// ## Allowed
/// ```dart
/// // READ — always allowed
/// supabase.from('events').select();
///
/// // EF invocation — always allowed
/// supabase.functions.invoke('create-event', body: {...});
///
/// // Suppressed with mandatory reason
/// // minglit_lints: allow-supabase-write — reason: EF migration pending until 2026-07-01
/// supabase.from('legacy_table').insert(data);
/// ```
class NoSupabaseWritesOutsideEfRule extends DartLintRule {
  const NoSupabaseWritesOutsideEfRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'no_supabase_writes_outside_ef',
    problemMessage:
        'Direct Supabase write operations are not allowed in Flutter apps. '
        'All writes must go through Edge Functions.',
    correctionMessage:
        'Use supabase.functions.invoke() instead. '
        'To suppress: add '
        '"// minglit_lints: allow-supabase-write — reason: <reason>" '
        'on the preceding line.',
  );

  static const _writeMethodNames = {'insert', 'update', 'delete', 'upsert'};

  /// Returns true if [name] is one of the write method names to be flagged.
  ///
  /// Exposed as static for unit testing.
  static bool isWriteMethodName(String name) =>
      _writeMethodNames.contains(name);

  /// Returns true if [commentText] is a valid allowlist suppression comment.
  ///
  /// Both the `allow-supabase-write` marker and a non-empty `reason:` value
  /// are required. A comment without a reason is treated as a violation.
  ///
  /// Exposed as static for unit testing.
  static bool matchesAllowlistComment(String commentText) {
    if (!commentText.contains('minglit_lints: allow-supabase-write')) {
      return false;
    }
    final reasonIdx = commentText.indexOf('reason:');
    if (reasonIdx == -1) return false;
    final reason = commentText.substring(reasonIdx + 7).trim();
    return reason.isNotEmpty;
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!isWriteMethodName(node.methodName.name)) return;

      // The direct target must be a .from('table') invocation.
      final target = node.target;
      if (target is! MethodInvocation) return;
      if (target.methodName.name != 'from') return;

      if (_isSuppressed(node)) return;

      reporter.atNode(node.methodName, _code);
    });
  }

  // Checks preceding comment tokens attached to the first token of the entire
  // method-chain expression (e.g. the `supabase` identifier in
  // `supabase.from('t').insert({})`).
  bool _isSuppressed(MethodInvocation node) {
    // beginToken.precedingComments is a CommentToken linked list; using Token?
    // to avoid the cast since CommentToken.next is exposed as Token?.
    Token? comment = node.beginToken.precedingComments;
    while (comment != null) {
      if (matchesAllowlistComment(comment.lexeme)) return true;
      comment = comment.next;
    }
    return false;
  }
}
