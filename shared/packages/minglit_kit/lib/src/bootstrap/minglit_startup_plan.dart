import 'package:minglit_kit/src/bootstrap/minglit_startup_result.dart';
import 'package:minglit_kit/src/bootstrap/minglit_startup_step.dart';
import 'package:minglit_kit/src/bootstrap/startup_error_policy.dart';
import 'package:minglit_kit/src/utils/log.dart';

/// Callback invoked when a non-critical startup step fails.
typedef MinglitStartupFailureHandler =
    void Function(MinglitStartupFailure failure);

/// Declarative startup step runner.
class MinglitStartupPlan {
  /// Creates a startup plan.
  const MinglitStartupPlan({required this.steps, this.onNonCriticalFailure});

  /// Ordered startup steps.
  final List<MinglitStartupStep> steps;

  /// Optional hook for app-specific logging or telemetry.
  final MinglitStartupFailureHandler? onNonCriticalFailure;

  /// Runs each startup step in order.
  ///
  /// Critical failures are rethrown. Platform/degradable failures are collected
  /// and execution continues.
  Future<MinglitStartupResult> run() async {
    final degradedFailures = <MinglitStartupFailure>[];

    for (final step in steps) {
      try {
        final future = step.run();
        final timeout = step.timeout;
        if (timeout == null) {
          await future;
        } else {
          await future.timeout(timeout);
        }
      } on Object catch (error, stackTrace) {
        if (isFatalStartupFailure(step.kind)) {
          Error.throwWithStackTrace(error, stackTrace);
        }

        final failure = MinglitStartupFailure(
          stepName: step.name,
          kind: step.kind,
          error: error,
          stackTrace: stackTrace,
        );
        degradedFailures.add(failure);
        final handler = onNonCriticalFailure;
        if (handler == null) {
          Log.e('Startup step warning: ${step.name}', error, stackTrace);
        } else {
          handler(failure);
        }
      }
    }

    return MinglitStartupResult(degradedFailures: degradedFailures);
  }
}
