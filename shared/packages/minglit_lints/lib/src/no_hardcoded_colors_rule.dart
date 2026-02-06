import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NoHardcodedColorsRule extends AnalysisRule {
  NoHardcodedColorsRule()
    : super(
        name: 'minglit_no_hardcoded_colors',
        description: 'Hardcoded colors are not allowed. Use MinglitColors.',
      );

  static const LintCode code = LintCode(
    'minglit_no_hardcoded_colors',
    'Hardcoded colors are not allowed. Use MinglitColors.',
    correctionMessage: 'Use MinglitColors from minglit_theme.dart.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry
      ..addInstanceCreationExpression(this, visitor)
      ..addPrefixedIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final NoHardcodedColorsRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null) return;

    final typeName = type.getDisplayString();
    if (typeName == 'Color' || typeName == 'Color?') {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'Colors') {
      rule.reportAtNode(node);
    }
  }
}
