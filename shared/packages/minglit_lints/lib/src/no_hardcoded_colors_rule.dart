import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedColorsRule extends DartLintRule {
  const NoHardcodedColorsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'minglit_no_hardcoded_colors',
    problemMessage: 'Hardcoded colors are not allowed. Use MinglitColors.',
    correctionMessage: 'Use MinglitColors from minglit_theme.dart.',
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
      if (typeName == 'Color' || typeName == 'Color?') {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name == 'Colors') {
        reporter.atNode(node, _code);
      }
    });
  }
}
