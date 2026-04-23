import 'dart:async';

import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:app_partner/src/features/checkin/widgets/checkin_scanner_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Fix #1097: widget test에서 MobileScannerPlatform을 스텁해 카메라 채널 호출을 막는다.
class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.shrink();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size.zero,
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<Set<CameraLensType>> getSupportedLenses() async => {};

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async => null;
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  late MobileScannerPlatform originalPlatform;
  late MobileScannerController scannerController;

  setUp(() {
    originalPlatform = MobileScannerPlatform.instance;
    MobileScannerPlatform.instance = _FakeMobileScannerPlatform();
    scannerController = MobileScannerController();
  });

  tearDown(() async {
    MobileScannerPlatform.instance = originalPlatform;
    await scannerController.dispose();
  });

  group('CheckinScannerOverlay 배너', () {
    testWidgets('idle 상태 — 배너 없음', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.idle),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('체크인 완료'), findsNothing);
      expect(find.text('이미 체크인된 참가자'), findsNothing);
      expect(find.text('입장 불가'), findsNothing);
    });

    testWidgets('idle → success 전환 — 성공 배너 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.idle),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(
              result: CheckinResult.success,
              userName: '홍길동',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('홍길동'), findsOneWidget);
    });

    testWidgets('idle → success (userName 없음) — "체크인 완료" 배너 표시', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.idle),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.success),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('체크인 완료'), findsOneWidget);
    });

    testWidgets('idle → alreadyCheckedIn — 중복 배너 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.idle),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.alreadyCheckedIn),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('이미 체크인된 참가자'), findsOneWidget);
    });

    testWidgets('idle → error — 오류 배너 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.idle),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.error),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('입장 불가'), findsOneWidget);
    });

    testWidgets('idle → invalid — 오류 배너 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.idle),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.invalid),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('입장 불가'), findsOneWidget);
    });

    testWidgets('배너 표시 중 opacity > 0 (애니메이션 방향 검증)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.idle),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _wrap(
          CheckinScannerOverlay(
            scannerController: scannerController,
            onManualCheckin: () {},
            state: const CheckinState(result: CheckinResult.success),
          ),
        ),
      );
      // 애니메이션 시작 직후 (0.1초) — 배너가 보여야 함 (opacity=1)
      await tester.pump(const Duration(milliseconds: 100));

      final opacityWidget = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.text('체크인 완료'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacityWidget.opacity, greaterThan(0.5));
    });
  });
}
