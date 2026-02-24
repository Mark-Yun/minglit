import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/error/listener.dart';

class NoHardcodedPaddingRule extends DartLintRule {
  const NoHardcodedPaddingRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'no_hardcoded_padding',
    problemMessage:
        'Avoid hardcoded padding values. Use design tokens instead.',
    correctionMessage: 'Replace with a MinglitSpacing token.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.staticType?.getDisplayString();
      if (typeName == 'Padding') {
        for (final arg in node.argumentList.arguments) {
          if (arg is NamedExpression && arg.name.label.name == 'padding') {
            _checkExpression(arg.expression, reporter);
          }
        }
      }
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

  void _checkExpression(Expression expression, ErrorReporter reporter) {
    if (expression is DoubleLiteral || expression is IntegerLiteral) {
      reporter.atNode(expression, _code);
    }
  }
}
