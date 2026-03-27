import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration — runs once before all tests in this package.
///
/// Loads NotoSansKR font so golden tests render Korean text correctly
/// instead of showing □□□ (Ahem font fallback).
// Fix #449: 테스트 환경에서 NotoSansKR를 선로드해 한글 golden 렌더링 깨짐(□)을 방지
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadNotoSansKR();
  await testMain();
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
