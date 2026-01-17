import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/no_hardcoded_padding_rule.dart';
import 'src/use_minglit_progress_indicator_rule.dart';

PluginBase createPlugin() => _MinglitLints();

class _MinglitLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const NoHardcodedPaddingRule(),
        const UseMinglitProgressIndicatorRule(),
      ];
}
