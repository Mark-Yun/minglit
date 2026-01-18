import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RequirePublicDocsRule extends DartLintRule {
  const RequirePublicDocsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'minglit_require_public_docs',
    problemMessage: 'Public members must be documented.',
    correctionMessage: 'Add a documentation comment (///).',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addDeclaration((node) {
      // 1. Private members are excluded
      final name = node.declaredElement?.name;
      if (name == null || name.startsWith('_')) return;

      // 2. Already documented members are excluded
      if (node.documentationComment != null) return;

      // 3. Overridden members are excluded
      final metadata = node.metadata;
      final isOverride = metadata.any(
        (annotation) => annotation.name.name == 'override',
      );
      if (isOverride) return;

      // 4. Flutter lifecycle methods are excluded
      const flutterLifecycleMethods = {
        'build',
        'createState',
        'initState',
        'dispose',
        'didUpdateWidget',
        'didChangeDependencies',
        'deactivate',
        'reassemble',
        'createState',
      };
      
      // Check if it's a method declaration and matches lifecycle methods
      if (node is MethodDeclaration) {
         if (flutterLifecycleMethods.contains(name)) return;
      }

      // Report lint
      reporter.atNode(node, _code);
    });
  }
}
