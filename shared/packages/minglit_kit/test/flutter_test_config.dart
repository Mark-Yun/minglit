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

  // ignore: do_not_use_environment
  final isCI =
      const bool.fromEnvironment('CI') || Platform.environment['CI'] == 'true';

  // CI: Ahem 폰트만 사용 (플랫폼 차이 없음, Alchemist CI 골든용)
  // Local: NotoSansKR 로드 (한글 렌더링, platform 골든용)
  if (!isCI) {
    await _loadNotoSansKR();
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

Future<void> _loadNotoSansKR() async {
  final fontLoader = FontLoader('NotoSansKR');
  final fontFile = File(
    'assets/fonts/Noto_Sans_KR/NotoSansKR-VariableFont_wght.ttf',
  );
  final bytes = await fontFile.readAsBytes();
  fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await fontLoader.load();
}
