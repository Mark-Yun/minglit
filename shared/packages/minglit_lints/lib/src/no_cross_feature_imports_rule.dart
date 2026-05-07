import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoCrossFeatureImportsRule extends DartLintRule {
  const NoCrossFeatureImportsRule() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'minglit_no_cross_feature_imports',
    problemMessage: 'Cross-feature imports are not allowed. '
        'Extract shared code to minglit_kit.',
    correctionMessage:
        'Move shared code to shared/packages/minglit_kit instead.',
  );

  // Matches: package:app_user/src/features/<feature>/...
  //          package:app_partner/src/features/<feature>/...
  static final _importedFeaturePattern = RegExp(
    '^package:(app_user|app_partner)/src/features/([^/]+)/',
  );

  // Matches the feature segment of the current file path
  static final _currentFilePattern = RegExp(
    '/(app_user|app_partner)/lib/src/features/([^/]+)/',
  );

  /// Returns true if [importUri] is a cross-feature import relative to
  /// [currentFilePath].
  ///
  /// Exposed as static for unit testing.
  static bool isCrossFeatureImport({
    required String currentFilePath,
    required String importUri,
  }) {
    final importMatch = _importedFeaturePattern.firstMatch(importUri);
    if (importMatch == null) return false;

    final importedApp = importMatch.group(1)!;
    final importedFeature = importMatch.group(2)!;

    final currentMatch = _currentFilePattern.firstMatch(currentFilePath);
    if (currentMatch == null) return false;

    final currentApp = currentMatch.group(1)!;
    final currentFeature = currentMatch.group(2)!;

    return currentApp == importedApp && currentFeature != importedFeature;
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      final importUri = node.uri.stringValue ?? '';
      if (isCrossFeatureImport(
        currentFilePath: resolver.path,
        importUri: importUri,
      )) {
        reporter.atNode(node, _code);
      }
    });
  }
}
