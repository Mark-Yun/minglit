import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedTextStyleRule extends DartLintRule {
  const NoHardcodedTextStyleRule() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_text_style',
    problemMessage:
        'Avoid hardcoded TextStyle. Use Theme.of(context).textTheme or design tokens.',
    correctionMessage: 'Use a theme text style.',
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
      if (typeName == 'TextStyle') {
        reporter.atNode(node, _code);
      }
    });
  }
}
