import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
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
    // runAsync를 사용하지 않아 미완료된 Future가 의도치 않게 resolve되는
    // 사이드이펙트를 방지한다 (예: 네이티브 플러그인 채널 호출 트리거 차단).
    try {
      final rootElement = tester.binding.rootElement;
      if (rootElement == null) return;

      final image = await captureImage(rootElement);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return;

      final bytes = Uint8List.view(byteData.buffer);
      final filename = '${testId}_step${step}_$phase.png';
      final dir = Directory('test/integration/goldens');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      // 동기 I/O: runAsync 없이 쓰므로 사이드이펙트가 없다.
      File('${dir.path}/$filename').writeAsBytesSync(bytes);
    } catch (e, st) {
      // ignore: avoid_print
      print('[GoldenCapture] capture failed: $e\n$st');
    }
  }
}
