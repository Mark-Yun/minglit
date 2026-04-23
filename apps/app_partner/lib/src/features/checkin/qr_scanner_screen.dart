import 'dart:async';

import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:app_partner/src/features/checkin/widgets/checkin_scanner_overlay.dart';
import 'package:app_partner/src/features/checkin/widgets/checkin_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR 스캐너 화면.
///
/// - 전체 화면 카메라 뷰 + AppBar 투명화
/// - 상단 요약 카드 (Phase 2에서 실시간 연동)
/// - 반응형 cutout (220 또는 화면 짧은 축 48% 미만)
/// - 플래시 / 수동 체크인 FAB
/// - 스캔 결과 배너 (기존 전체 화면 오버레이 대체)
// Fix #1809: QR 스캐너 화면 Phase 1 개편 — 요약 카드 + 반응형 cutout + 배너 피드백
class QRScannerScreen extends ConsumerStatefulWidget {
  // Fix #523: event 파라미터 추가 — 어떤 이벤트에 체크인하는지 사용자에게 표시
  const QRScannerScreen({required this.event, super.key});

  final Event event;

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    // Fix #1072: async dispose()는 super.dispose()가 비동기로 호출되어 프레임워크 오류 발생.
    // MobileScannerController.dispose()의 Future는 unawaited로 처리한다.
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkinControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CloseButton(color: MinglitColors.background),
        title: Column(
          children: [
            Text(
              '티켓 스캔',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: MinglitColors.background,
              ),
            ),
            if (widget.event.title != null)
              Text(
                widget.event.title!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: MinglitColors.background.withValues(
                    alpha: MinglitOpacity.scrimDark,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Full-screen camera
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                // Fix #382: 강제 언래핑 제거 — local variable로 null 안전성 확보
                final rawValue = barcode.rawValue;
                if (rawValue != null) {
                  unawaited(
                    ref
                        .read(checkinControllerProvider.notifier)
                        .processQR(rawValue),
                  );
                }
              }
            },
          ),

          // 2. Scrim + cutout + FABs + result banner
          CheckinScannerOverlay(
            scannerController: _scannerController,
            onManualCheckin: () => _showManualCheckinSheet(context),
            state: state,
          ),

          // 3. Summary card — positioned below AppBar
          //    Phase 2: replace checkedIn/total with checkinStatsControllerProvider
          const SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: kToolbarHeight),
                CheckinSummaryCard(checkedIn: 0, total: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualCheckinSheet(BuildContext context) {
    // Phase 4: ManualCheckinSheet
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(child: Text('수동 체크인 — Phase 4에서 구현 예정')),
      ),
    );
  }
}
