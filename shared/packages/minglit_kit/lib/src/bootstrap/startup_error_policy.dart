import 'package:minglit_kit/src/bootstrap/minglit_startup_step.dart';

/// Captured failure from a startup step.
class MinglitStartupFailure {
  /// Creates a startup failure.
  const MinglitStartupFailure({
    required this.stepName,
    required this.kind,
    required this.error,
    required this.stackTrace,
  });

  /// Name of the failed step.
  final String stepName;

  /// Failure policy category of the failed step.
  final MinglitStartupStepKind kind;

  /// Original error.
  final Object error;

  /// Original stack trace.
  final StackTrace stackTrace;

  @override
  String toString() => 'Startup step "$stepName" failed: $error';
}

/// Returns true when a failure must block app entry.
bool isFatalStartupFailure(MinglitStartupStepKind kind) {
  return kind == MinglitStartupStepKind.critical;
}
