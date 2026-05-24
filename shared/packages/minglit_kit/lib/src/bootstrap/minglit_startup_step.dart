/// App startup step category.
enum MinglitStartupStepKind {
  /// Required for a valid app session. Failure blocks app entry.
  critical,

  /// Platform-level best-effort setup.
  ///
  /// Failure is logged and app entry continues.
  platform,

  /// Optional SDK or feature setup. Failure is logged and app entry continues.
  degradable,
}

/// Async startup work with an explicit failure policy.
class MinglitStartupStep {
  /// Creates a startup step.
  const MinglitStartupStep({
    required this.name,
    required this.kind,
    required this.run,
    this.timeout,
  });

  /// Creates a critical step.
  factory MinglitStartupStep.critical(
    String name,
    Future<void> Function() run, {
    Duration? timeout,
  }) {
    return MinglitStartupStep(
      name: name,
      kind: MinglitStartupStepKind.critical,
      run: run,
      timeout: timeout,
    );
  }

  /// Creates a platform step.
  factory MinglitStartupStep.platform(
    String name,
    Future<void> Function() run, {
    Duration? timeout,
  }) {
    return MinglitStartupStep(
      name: name,
      kind: MinglitStartupStepKind.platform,
      run: run,
      timeout: timeout,
    );
  }

  /// Creates a degradable step.
  factory MinglitStartupStep.degradable(
    String name,
    Future<void> Function() run, {
    Duration? timeout,
  }) {
    return MinglitStartupStep(
      name: name,
      kind: MinglitStartupStepKind.degradable,
      run: run,
      timeout: timeout,
    );
  }

  /// Stable name for logs and tests.
  final String name;

  /// Failure policy category.
  final MinglitStartupStepKind kind;

  /// Work performed by this step.
  final Future<void> Function() run;

  /// Optional bounded wait time for this step.
  final Duration? timeout;
}
