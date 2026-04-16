import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// KEEP IN SYNC WITH apps/app_user/test/integration/utils/golden_capture.dart

/// CUJ 스텝별 골든 캡처 헬퍼.
///
/// QA 네이밍 규칙: `{testId}_step{step}_{phase}.png`
/// - testId: cuj_p01, cuj_p02 등
/// - step: 0부터 순차 증가
/// - phase: setup | before | after | error
///
/// 캡처 실패는 삼켜진다 — 테스트 실패로 이어지지 않는다.
/// 파일은 `test/integration/goldens/` 디렉토리에 저장된다.
///
/// 사용 예:
/// ```dart
/// final capture = GoldenCapture('cuj_p01');
/// await capture.setup(tester, 0);  // cuj_p01_step0_setup.png
/// await capture.before(tester, 1); // cuj_p01_step1_before.png
/// await capture.after(tester, 2);  // cuj_p01_step2_after.png
/// ```
class GoldenCapture {
  GoldenCapture(this.testId);

  final String testId;

  /// 초기 상태 캡처 (pumpWidget 직후, 첫 액션 전)
  Future<void> setup(WidgetTester tester, int step) =>
      _capture(tester, step, 'setup');

  /// 액션 직전 캡처
  Future<void> before(WidgetTester tester, int step) =>
      _capture(tester, step, 'before');

  /// 액션 후 pumpAndSettle 완료 시점 캡처
  Future<void> after(WidgetTester tester, int step) =>
      _capture(tester, step, 'after');

  /// 에러 상태 유발 후 캡처
  Future<void> error(WidgetTester tester, int step) =>
      _capture(tester, step, 'error');

  Future<void> _capture(WidgetTester tester, int step, String phase) async {
    // 캡처 실패는 삼켜진다 — 회귀 비교가 아닌 시각 베이스라인 생성이 목적이므로
    // 테스트 실패로 이어져서는 안 된다.
    try {
      await tester.runAsync(() async {
        final image = await _renderToImage(tester);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (byteData == null) return;
        final bytes = Uint8List.view(byteData.buffer);
        final filename = '${testId}_step${step}_$phase.png';
        final dir = Directory('test/integration/goldens');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        await File('${dir.path}/$filename').writeAsBytes(bytes, flush: true);
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('[GoldenCapture] capture failed: $e\n$st');
    }
  }

  Future<ui.Image> _renderToImage(WidgetTester tester) async {
    final rootElement = tester.binding.rootElement;
    if (rootElement != null) {
      return captureImage(rootElement);
    }
    final renderView = tester.binding.renderViews.first;
    final layer = renderView.debugLayer;
    if (layer is OffsetLayer) {
      return layer.toImage(renderView.paintBounds);
    }
    throw StateError('Could not find a paintable layer to capture.');
  }
}
