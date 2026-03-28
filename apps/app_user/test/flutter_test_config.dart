import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration — runs once before all tests in this package.
///
/// 1. Loads NotoSansKR font for Korean text rendering (Fix #449)
/// 2. Configures Alchemist for CI/platform golden separation (Fix #572)
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadNotoSansKR();

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

Future<void> _loadNotoSansKR() async {
  final fontLoader = FontLoader('NotoSansKR');
  final fontFile = File(
    '../../shared/packages/minglit_kit/assets/fonts/Noto_Sans_KR/NotoSansKR-VariableFont_wght.ttf',
  );
  final bytes = await fontFile.readAsBytes();
  fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await fontLoader.load();
}
