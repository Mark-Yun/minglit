import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

// KEEP IN SYNC WITH apps/app_partner/test/integration/utils/golden_capture.dart

/// CUJ 스텝별 골든 캡처 헬퍼.
///
/// QA 네이밍 규칙: `{testId}_step{step}_{phase}.png`
/// - testId: cuj_u01, flow_u_search 등
/// - step: 0부터 순차 증가
/// - phase: setup | before | after | error
///
/// 캡처 실패는 삼켜진다 — 테스트 실패로 이어지지 않는다.
/// 파일은 `test/integration/goldens/` 디렉토리에 저장된다.
///
/// [tester.runAsync]를 사용하지 않아 사이드이펙트 없이 안전하게 캡처한다.
///
/// 사용 예:
/// ```dart
/// final capture = GoldenCapture('cuj_u01');
/// await capture.setup(tester, 0);  // cuj_u01_step0_setup.png
/// await capture.before(tester, 1); // cuj_u01_step1_before.png
/// await capture.after(tester, 2);  // cuj_u01_step2_after.png
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
    //
    // Fix #1677: runAsync로 캡처 — Flutter 테스트 환경에서 fake async 타이머가
    // 동작하지 않아 captureImage().timeout()이 실제로 발화하지 않는 문제 해결.
    // runAsync 안에서는 실제 타이머가 동작하므로 30s timeout이 올바르게 발화됨.
    // 캡처 시점(pumpAndSettle 완료 후)에는 미완료 native 플러그인 Future가 없으므로
    // runAsync 사용에 따른 사이드이펙트 위험이 낮다.
    try {
      final rootElement = tester.binding.rootElement;
      if (rootElement == null) return;

      // Fix #1677: runAsync to allow real timers (timeout) and GPU-less rendering.
      final image = await tester.runAsync(
        () => captureImage(rootElement).timeout(const Duration(seconds: 30)),
      );
      if (image == null) return;

      // Fix #1458: ensure dispose is called even if toByteData throws
      late final Uint8List bytes;
      try {
        final byteData = await tester.runAsync(
          () => image
              .toByteData(format: ui.ImageByteFormat.png)
              .timeout(const Duration(seconds: 30)),
        );
        if (byteData == null) return;
        bytes = Uint8List.view(byteData.buffer);
      } finally {
        image.dispose();
      }
      final filename = '${testId}_step${step}_$phase.png';
      // createSync(recursive: true) is idempotent — no existsSync needed
      final dir = Directory('test/integration/goldens')
        ..createSync(recursive: true);
      File('${dir.path}/$filename').writeAsBytesSync(bytes);
    } catch (e, st) {
      // ignore: avoid_print
      print('[GoldenCapture] capture failed: $e\n$st');
    }
  }
}
