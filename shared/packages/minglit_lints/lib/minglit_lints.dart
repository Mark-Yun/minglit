import 'dart:io';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/no_hardcoded_colors_rule.dart';
import 'src/no_hardcoded_padding_rule.dart';
import 'src/no_hardcoded_text_style_rule.dart';
import 'src/use_minglit_progress_indicator_rule.dart';

PluginBase createPlugin() {
  try {
    File('minglit_lints_loaded.txt').writeAsStringSync('loaded');
  } catch (_) {}
  return _MinglitLints();
}

class _MinglitLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const NoHardcodedPaddingRule(),
        const UseMinglitProgressIndicatorRule(),
        const NoHardcodedColorsRule(),
        const NoHardcodedTextStyleRule(),
      ];
}
