import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class UseMinglitAsyncValueWidgetRule extends DartLintRule {
  const UseMinglitAsyncValueWidgetRule() : super(code: _code);

  static const _code = LintCode(
    name: 'use_minglit_async_value_widget',
    problemMessage:
        'Avoid using AsyncValue.when/maybeWhen directly. Use MinglitAsyncValueWidget instead for consistent loading and error states.',
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

      // Check if the target type is AsyncValue
      // We check for 'AsyncValue' in the display string.
      // A more robust check would involve checking the element's library,
      // but this is usually sufficient for project-specific lints.
      if (type.getDisplayString().contains('AsyncValue')) {
        reporter.atNode(node.methodName, _code);
      }
    });
  }
}
