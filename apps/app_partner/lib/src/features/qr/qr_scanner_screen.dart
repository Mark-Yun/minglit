import 'dart:async';

import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(checkinControllerProvider, (prev, next) {
      if (!mounted) return;
      switch (next.result) {
        case CheckinResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 입장 확인: ${next.userName ?? ""}'),
              backgroundColor: MinglitColors.success,
            ),
          );
        case CheckinResult.invalid:
        case CheckinResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message ?? '처리 실패'),
              backgroundColor: MinglitColors.error,
            ),
          );
        case CheckinResult.alreadyCheckedIn:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 입장 처리된 티켓입니다'),
              backgroundColor: MinglitColors.warning,
            ),
          );
        case CheckinResult.idle:
          setState(() => _isProcessing = false);
        case CheckinResult.processing:
          break;
      }
    });
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    unawaited(
      ref.read(checkinControllerProvider.notifier).processQR(code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: MinglitColors.textPrimary,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Custom Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              MinglitColors.textPrimary.withValues(alpha: 0.54),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: MinglitColors.textPrimary,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: MinglitColors.background,
                      borderRadius: BorderRadius.circular(MinglitRadius.card),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Border for the hole
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: MinglitColors.background, width: 2),
                borderRadius: BorderRadius.circular(MinglitRadius.card),
              ),
            ),
          ),

          // Close Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: MinglitColors.background,
                size: 30,
              ),
              onPressed: () => context.pop(),
            ),
          ),

          // Title
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Text(
              '입장 QR 스캔',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: MinglitColors.background,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Flash Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.flash_on,
                  color: MinglitColors.background,
                  size: 30,
                ),
                onPressed: _controller.toggleTorch,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
