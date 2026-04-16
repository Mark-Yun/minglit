import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// CUJ 스텝별 골든 캡처 헬퍼.
///
/// QA 네이밍 규칙: `{testId}_step{step}_{phase}.png`
/// - testId: cuj_p01, cuj_p02 등
/// - step: 0부터 순차 증가
/// - phase: setup | before | after | error
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
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/${testId}_step${step}_$phase.png'),
    );
  }
}
