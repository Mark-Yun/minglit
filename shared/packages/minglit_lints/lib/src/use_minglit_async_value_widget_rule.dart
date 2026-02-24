import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class UseMinglitAsyncValueWidgetRule extends DartLintRule {
  const UseMinglitAsyncValueWidgetRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'use_minglit_async_value_widget',
    problemMessage: 'Avoid using AsyncValue.when/maybeWhen directly. '
        'Use MinglitAsyncValueWidget instead for consistent '
        'loading and error states.',
    correctionMessage: 'Replace with MinglitAsyncValueWidget.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (methodName != 'when' && methodName != 'maybeWhen') return;

      final target = node.target;
      if (target == null) return;

      final type = target.staticType;
      if (type == null) return;

      if (type.getDisplayString().contains('AsyncValue')) {
        reporter.atNode(node.methodName, _code);
      }
    });
  }
}
