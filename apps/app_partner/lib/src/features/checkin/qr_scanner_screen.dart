import 'dart:async';
import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// **QR Scanner Screen**
///
/// Full-screen camera view to scan user tickets.
/// Provides immediate visual feedback (Green/Red) based on result.
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkinControllerProvider);
    final theme = Theme.of(context);

    Color? overlayColor;
    if (state.result == CheckinResult.success) {
      overlayColor = Colors.green.withValues(alpha: 0.8);
    } else if (state.result != CheckinResult.idle) {
      overlayColor = theme.colorScheme.error.withValues(alpha: 0.8);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CloseButton(color: Colors.white),
        title: const Text('티켓 스캔', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          // 1. Scanner View
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  unawaited(
                    ref
                        .read(checkinControllerProvider.notifier)
                        .processQR(barcode.rawValue!),
                  );
                }
              }
            },
          ),

          // 2. Scan Window Overlay (Standard Scanner look)
          _buildScanWindow(context),

          // 3. Result Overlay (Success/Fail)
          if (overlayColor != null)
            _ResultFeedbackOverlay(
              color: overlayColor,
              state: state,
            ),
        ],
      ),
    );
  }

  Widget _buildScanWindow(BuildContext context) {
    return Container(
      decoration: const ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
        ),
      ),
    );
  }
}

class _ResultFeedbackOverlay extends StatelessWidget {
  const _ResultFeedbackOverlay({required this.color, required this.state});

  final Color color;
  final CheckinState state;

  @override
  Widget build(BuildContext context) {
    final icon = state.result == CheckinResult.success
        ? Icons.check_circle
        : Icons.error;
    final title = state.result == CheckinResult.success ? '체크인 완료' : '입장 제한';
    final subTitle = state.userName ?? state.message ?? '';

    return Container(
      color: color,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                subTitle,
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// Helper class for QR Overlay shape
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRect(
        Rect.fromCenter(
          center: Offset(width / 2, height / 2),
          width: cutOutSize,
          height: cutOutSize,
        ),
      );

    canvas.drawPath(
      backgroundPath,
      Paint()
        ..color = overlayColor
        ..style = PaintingStyle.fill,
    );

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final center = Offset(width / 2, height / 2);
    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Draw borders (corners)
    final path1 = Path()
      ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.left, cutOutRect.top)
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.top);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
      ..lineTo(cutOutRect.right, cutOutRect.top)
      ..lineTo(cutOutRect.right, cutOutRect.top + borderLength);
    canvas.drawPath(path2, paint);

    final path3 = Path()
      ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.right, cutOutRect.bottom)
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);
    canvas.drawPath(path3, paint);

    final path4 = Path()
      ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
      ..lineTo(cutOutRect.left, cutOutRect.bottom)
      ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);
    canvas.drawPath(path4, paint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth,
    overlayColor: overlayColor,
  );
}
