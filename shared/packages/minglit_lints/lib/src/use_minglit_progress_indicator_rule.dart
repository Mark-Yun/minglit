import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class UseMinglitProgressIndicatorRule extends DartLintRule {
  const UseMinglitProgressIndicatorRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'use_minglit_progress_indicator',
    problemMessage: 'Avoid using default ProgressIndicator. '
        'Use shared widgets (e.g., MinglitCircularProgressIndicator) instead.',
    correctionMessage: 'Replace with MinglitCircularProgressIndicator '
        'or MinglitLinearProgressIndicator.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.staticType?.getDisplayString();
      if (typeName == 'CircularProgressIndicator' ||
          typeName == 'LinearProgressIndicator') {
        reporter.atNode(node, _code);
      }
    });
  }
}
