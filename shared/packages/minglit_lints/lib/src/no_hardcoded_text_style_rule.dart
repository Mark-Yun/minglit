import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NoHardcodedTextStyleRule extends AnalysisRule {
  NoHardcodedTextStyleRule()
    : super(
        name: 'minglit_no_hardcoded_text_style',
        description: 'Hardcoded TextStyle is discouraged.',
      );

  static const LintCode code = LintCode(
    'minglit_no_hardcoded_text_style',
    'Hardcoded TextStyle is discouraged.',
    correctionMessage: 'Use Theme.of(context).textTheme or MinglitTextStyles.',
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

  final NoHardcodedTextStyleRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null) return;

    final typeName = type.getDisplayString();
    if (typeName == 'TextStyle') {
      rule.reportAtNode(node);
    }
  }
}
