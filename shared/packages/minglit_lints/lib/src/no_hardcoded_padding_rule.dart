import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NoHardcodedPaddingRule extends AnalysisRule {
  NoHardcodedPaddingRule()
    : super(
        name: 'no_hardcoded_padding',
        description:
            'Avoid hardcoded padding values. Use design tokens instead.',
      );

  static const LintCode code = LintCode(
    'no_hardcoded_padding',
    'Avoid hardcoded padding values. '
        'Use design tokens (e.g., MinglitSpacing) instead.',
    correctionMessage: 'Replace with a MinglitSpacing token.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final NoHardcodedPaddingRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null) return;

    final typeName = type.getDisplayString();

    // Check for Padding widget
    if (typeName == 'Padding') {
      final arguments = node.argumentList.arguments;
      for (final arg in arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'padding') {
          _checkExpression(arg.expression);
        }
      }
    }

    // Check for EdgeInsets constructors
    if (typeName == 'EdgeInsets' || typeName == 'EdgeInsetsDirectional') {
      for (final arg in node.argumentList.arguments) {
        if (arg is NamedExpression) {
          _checkExpression(arg.expression);
        } else {
          _checkExpression(arg);
        }
      }
    }
  }

  void _checkExpression(Expression expression) {
    if (expression is DoubleLiteral || expression is IntegerLiteral) {
      rule.reportAtNode(expression);
    }
  }
}
