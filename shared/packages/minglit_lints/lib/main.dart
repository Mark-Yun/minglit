import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:minglit_lints/src/no_hardcoded_colors_rule.dart';
import 'package:minglit_lints/src/no_hardcoded_padding_rule.dart';
import 'package:minglit_lints/src/no_hardcoded_text_style_rule.dart';
import 'package:minglit_lints/src/require_public_docs_rule.dart';
import 'package:minglit_lints/src/use_minglit_async_value_widget_rule.dart';
import 'package:minglit_lints/src/use_minglit_progress_indicator_rule.dart';

final plugin = MinglitLintsPlugin();

class MinglitLintsPlugin extends Plugin {
  @override
  String get name => 'minglit_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(NoHardcodedColorsRule())
      ..registerWarningRule(NoHardcodedTextStyleRule())
      ..registerWarningRule(NoHardcodedPaddingRule())
      ..registerWarningRule(UseMinglitProgressIndicatorRule())
      ..registerWarningRule(UseMinglitAsyncValueWidgetRule())
      ..registerWarningRule(RequirePublicDocsRule());
  }
}
