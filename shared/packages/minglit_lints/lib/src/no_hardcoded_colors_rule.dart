import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedColorsRule extends DartLintRule {
  const NoHardcodedColorsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_colors',
    problemMessage:
        'Avoid hardcoded colors. Use MinglitTheme or design tokens instead.',
    correctionMessage: 'Replace with a design token color.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      if (type == null) return;

      final typeName = type.getDisplayString();
      if (typeName == 'Color' || typeName == 'Color?') {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name == 'Colors') {
        reporter.atNode(node, _code);
      }
    });
  }
}
