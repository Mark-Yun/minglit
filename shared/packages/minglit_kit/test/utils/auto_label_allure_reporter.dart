import 'package:allure_report/allure_report.dart';
import 'package:allure_report/src/test_report.dart';

/// AllureReporter that auto-derives epic/feature labels from test file paths.
///
/// Uses the convention `features/<feature>/<layer>/` to extract:
/// - epic: feature name (e.g. auth, event, payment)
/// - feature: layer name (e.g. logic, ui, data)
///
/// Zero test file changes required.
class AutoLabelAllureReporter extends AllureReporter {
  static final _featureRegex = RegExp(r'features/(\w+)');
  static final _layerRegex = RegExp(r'features/\w+/(\w+)');

  @override
  Future<void> onReportCreated(TestReport report) async {
    final test = report.start?.test;
    if (test == null) return super.onReportCreated(report);

    final suitePath = suites[test.suiteID]?.path ?? '';

    final featureMatch = _featureRegex.firstMatch(suitePath);
    if (featureMatch != null) {
      extraLabels.putIfAbsent(test.id, () => {})['epic'] =
          featureMatch.group(1)!;
    }

    final layerMatch = _layerRegex.firstMatch(suitePath);
    if (layerMatch != null) {
      extraLabels.putIfAbsent(test.id, () => {})['feature'] =
          layerMatch.group(1)!;
    }

    return super.onReportCreated(report);
  }
}
