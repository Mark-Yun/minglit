import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:minglit_lints/src/no_hardcoded_colors_rule.dart';
import 'package:minglit_lints/src/no_hardcoded_padding_rule.dart';
import 'package:minglit_lints/src/no_hardcoded_text_style_rule.dart';
import 'package:minglit_lints/src/require_public_docs_rule.dart';
import 'package:minglit_lints/src/use_minglit_async_value_widget_rule.dart';
import 'package:minglit_lints/src/use_minglit_progress_indicator_rule.dart';

PluginBase createPlugin() => _MinglitLintsPlugin();

class _MinglitLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const NoHardcodedColorsRule(),
        const NoHardcodedPaddingRule(),
        const NoHardcodedTextStyleRule(),
        const UseMinglitProgressIndicatorRule(),
        const UseMinglitAsyncValueWidgetRule(),
        const RequirePublicDocsRule(),
      ];
}
