import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RequirePublicDocsRule extends DartLintRule {
  const RequirePublicDocsRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'minglit_require_public_docs',
    problemMessage: 'Public members must be documented.',
    correctionMessage: 'Add a documentation comment (///).',
  );

  static const _flutterLifecycleMethods = {
    'build',
    'createState',
    'initState',
    'dispose',
    'didUpdateWidget',
    'didChangeDependencies',
    'deactivate',
    'reassemble',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    void check(AnnotatedNode node, String name) {
      if (name.startsWith('_')) return;
      if (node.documentationComment != null) return;
      final isOverride = node.metadata.any((a) => a.name.name == 'override');
      if (isOverride) return;
      reporter.atNode(node, _code);
    }

    context.registry
        .addClassDeclaration((node) => check(node, node.name.lexeme));
    context.registry.addMethodDeclaration((node) {
      if (_flutterLifecycleMethods.contains(node.name.lexeme)) return;
      check(node, node.name.lexeme);
    });
    context.registry
        .addFunctionDeclaration((node) => check(node, node.name.lexeme));
    context.registry
        .addEnumDeclaration((node) => check(node, node.name.lexeme));
    context.registry
        .addMixinDeclaration((node) => check(node, node.name.lexeme));
    context.registry
        .addExtensionTypeDeclaration((node) => check(node, node.name.lexeme));
    context.registry.addTopLevelVariableDeclaration((node) {
      for (final v in node.variables.variables) {
        check(node, v.name.lexeme);
      }
    });
  }
}
