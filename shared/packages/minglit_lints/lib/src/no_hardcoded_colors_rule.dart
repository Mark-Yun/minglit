import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/error/listener.dart';

class NoHardcodedColorsRule extends DartLintRule {
  const NoHardcodedColorsRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'minglit_no_hardcoded_colors',
    problemMessage: 'Hardcoded colors are not allowed. Use MinglitColors.',
    correctionMessage: 'Use MinglitColors from minglit_theme.dart.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name == 'Colors') {
        reporter.atNode(node, _code);
      }
    });
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.staticType?.getDisplayString();
      if (typeName == 'Color' || typeName == 'Color?') {
        reporter.atNode(node, _code);
      }
    });
  }
}
