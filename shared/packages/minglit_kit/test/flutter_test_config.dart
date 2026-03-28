import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // bool.fromEnvironment reads --dart-define compile-time constants.
  // Platform.environment reads OS env vars at runtime.
  // GitHub Actions sets CI=true as an OS env var, so we check both.
  // ignore: do_not_use_environment
  final isCI =
      const bool.fromEnvironment('CI') ||
      Platform.environment['CI'] == 'true';
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: !isCI,
      ),
    ),
    run: testMain,
  );
}
