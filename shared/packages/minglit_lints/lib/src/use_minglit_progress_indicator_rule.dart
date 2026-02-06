import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class UseMinglitProgressIndicatorRule extends AnalysisRule {
  UseMinglitProgressIndicatorRule()
    : super(
        name: 'use_minglit_progress_indicator',
        description:
            'Avoid using default ProgressIndicator. '
            'Use shared widgets instead.',
      );

  static const LintCode code = LintCode(
    'use_minglit_progress_indicator',
    'Avoid using default ProgressIndicator. '
        'Use shared widgets '
        '(e.g., MinglitCircularProgressIndicator) instead.',
    correctionMessage:
        'Replace with MinglitCircularProgressIndicator '
        'or MinglitLinearProgressIndicator.',
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

  final UseMinglitProgressIndicatorRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null) return;

    final typeName = type.getDisplayString();

    if (typeName == 'CircularProgressIndicator' ||
        typeName == 'LinearProgressIndicator') {
      rule.reportAtNode(node);
    }
  }
}
