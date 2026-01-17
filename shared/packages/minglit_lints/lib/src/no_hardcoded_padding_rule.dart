import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedPaddingRule extends DartLintRule {
  const NoHardcodedPaddingRule() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_padding',
    problemMessage:
        'Avoid hardcoded padding values. Use design tokens (e.g., MinglitSpacing) instead.',
    correctionMessage: 'Replace with a MinglitSpacing token.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      if (type == null) return;

      final typeName = type.getDisplayString();

      // Check for Padding widget
      if (typeName == 'Padding') {
        final arguments = node.argumentList.arguments;
        for (final arg in arguments) {
          if (arg is NamedExpression && arg.name.label.name == 'padding') {
            _checkExpression(arg.expression, reporter);
          }
        }
      }

      // Check for EdgeInsets constructors
      if (typeName == 'EdgeInsets' || typeName == 'EdgeInsetsDirectional') {
        for (final arg in node.argumentList.arguments) {
          if (arg is NamedExpression) {
            _checkExpression(arg.expression, reporter);
          } else {
            _checkExpression(arg, reporter);
          }
        }
      }
    });
  }

  void _checkExpression(Expression expression, DiagnosticReporter reporter) {
    if (expression is DoubleLiteral || expression is IntegerLiteral) {
      reporter.atNode(expression, _code);
    }
  }
}
