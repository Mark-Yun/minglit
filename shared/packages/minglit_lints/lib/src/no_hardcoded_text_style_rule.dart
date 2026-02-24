import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedTextStyleRule extends DartLintRule {
  const NoHardcodedTextStyleRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'minglit_no_hardcoded_text_style',
    problemMessage: 'Hardcoded TextStyle is discouraged.',
    correctionMessage: 'Use Theme.of(context).textTheme or MinglitTextStyles.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.staticType?.getDisplayString();
      if (typeName == 'TextStyle') {
        reporter.atNode(node, _code);
      }
    });
  }
}
