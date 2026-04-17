import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration — runs once before all tests in this package.
///
/// 1. Loads Pretendard font for Korean text rendering (Fix #1521)
/// 2. Configures Alchemist for CI/platform golden separation (Fix #572)
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final isCI =
      const bool.fromEnvironment('CI') || Platform.environment['CI'] == 'true';

  // CI: Ahem 폰트만 사용 (플랫폼 차이 없음, Alchemist CI 골든용)
  // Local: Pretendard 로드 (한글 렌더링, platform 골든용)
  if (!isCI) {
    await _loadPretendard();
  }
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: !isCI,
      ),
    ),
    run: testMain,
  );
}

Future<void> _loadPretendard() async {
  final fontLoader = FontLoader('Pretendard');
  final fontFile = File(
    'assets/fonts/Pretendard/PretendardVariable.ttf',
  );
  if (!await fontFile.exists()) {
    // Fallback for different execution contexts
    return;
  }
  final bytes = await fontFile.readAsBytes();
  fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await fontLoader.load();
}
