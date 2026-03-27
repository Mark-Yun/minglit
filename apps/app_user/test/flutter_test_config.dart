import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration — runs once before all tests in this package.
///
/// Loads NotoSansKR font so golden tests render Korean text correctly
/// instead of showing □□□ (Ahem font fallback).
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
