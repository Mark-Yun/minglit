import 'package:minglit_kit/src/bootstrap/startup_error_policy.dart';

/// Result of a startup plan run.
class MinglitStartupResult {
  /// Creates a startup result.
  const MinglitStartupResult({required this.degradedFailures});

  /// Non-critical failures that were logged and skipped.
  final List<MinglitStartupFailure> degradedFailures;

  /// True when one or more non-critical services failed during startup.
  bool get isDegraded => degradedFailures.isNotEmpty;
}
