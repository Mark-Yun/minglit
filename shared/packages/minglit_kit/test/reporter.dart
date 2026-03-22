import 'package:test_reporter/test_reporter.dart';

import 'utils/auto_label_allure_reporter.dart';

TestReporter create() {
  return AutoLabelAllureReporter();
}
