import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class UseMinglitAsyncValueWidgetRule extends AnalysisRule {
  UseMinglitAsyncValueWidgetRule()
    : super(
        name: 'use_minglit_async_value_widget',
        description:
            'Avoid using AsyncValue.when/maybeWhen directly. '
            'Use MinglitAsyncValueWidget instead.',
      );

  static const LintCode code = LintCode(
    'use_minglit_async_value_widget',
    'Avoid using AsyncValue.when/maybeWhen directly. '
        'Use MinglitAsyncValueWidget instead for consistent '
        'loading and error states.',
    correctionMessage: 'Replace with MinglitAsyncValueWidget.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseMinglitAsyncValueWidgetRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName != 'when' && methodName != 'maybeWhen') return;

    final target = node.target;
    if (target == null) return;

    final type = target.staticType;
    if (type == null) return;

    // Check if the target type is AsyncValue
    if (type.getDisplayString().contains('AsyncValue')) {
      rule.reportAtNode(node.methodName);
    }
  }
}
