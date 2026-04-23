import 'dart:math' as math;

import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR 스캐너 오버레이.
///
/// - 반응형 cutout (최대 220, 기기 너비 48% 미만)
/// - 플래시 / 수동 체크인 FAB (우상단)
/// - 스캔 결과 배너 (상단 슬라이드-인, 0.6s)
class CheckinScannerOverlay extends StatefulWidget {
  const CheckinScannerOverlay({
    required this.scannerController,
    required this.onManualCheckin,
    required this.state,
    super.key,
  });

  final MobileScannerController scannerController;
  final VoidCallback onManualCheckin;
  final CheckinState state;

  @override
  State<CheckinScannerOverlay> createState() => _CheckinScannerOverlayState();
}

class _CheckinScannerOverlayState extends State<CheckinScannerOverlay>
    with TickerProviderStateMixin {
  bool _flashOn = false;
  late AnimationController _bannerController;
  late Animation<Offset> _bannerSlide;
  late Animation<double> _bannerFade;
  CheckinResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bannerSlide =
        Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _bannerController,
            curve: const Interval(0, 0.25, curve: Curves.easeOutBack),
          ),
        );
    _bannerFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _bannerController,
        curve: const Interval(0.75, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(CheckinScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final result = widget.state.result;
    if (result != oldWidget.state.result &&
        result != CheckinResult.idle &&
        result != CheckinResult.processing) {
      _triggerBanner(result);
    }
  }

  void _triggerBanner(CheckinResult result) {
    setState(() => _lastResult = result);
    _triggerHaptic(result);
    _bannerController
      ..reset()
      ..forward();
  }

  void _triggerHaptic(CheckinResult result) {
    switch (result) {
      case CheckinResult.success:
        HapticFeedback.mediumImpact();
      case CheckinResult.alreadyCheckedIn:
        HapticFeedback.lightImpact();
      case CheckinResult.invalid:
      case CheckinResult.error:
        HapticFeedback.heavyImpact();
      case CheckinResult.idle:
      case CheckinResult.processing:
        break;
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cutOut = math.min(220, size.shortestSide * 0.48);

    return Stack(
      children: [
        // Scrim + cutout frame
        _ScanFrame(cutOutSize: cutOut),

        // Hint text below cutout
        Positioned(
          bottom: size.height * 0.22,
          left: MinglitSpacing.screenEdge,
          right: MinglitSpacing.screenEdge,
          child: Text(
            '참가자의 QR 코드를 프레임 안에 비추세요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ),

        // FABs (top-right)
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(
                top: kToolbarHeight + MinglitSpacing.medium,
                right: MinglitSpacing.medium,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScanFab(
                    icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                    isActive: _flashOn,
                    onTap: () {
                      setState(() => _flashOn = !_flashOn);
                      widget.scannerController.toggleTorch();
                    },
                  ),
                  const SizedBox(height: MinglitSpacing.sm),
                  _ScanFab(
                    icon: Icons.manage_search,
                    onTap: widget.onManualCheckin,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Success/fail banner (top)
        if (_lastResult != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _bannerController,
              builder: (_, _) => Opacity(
                opacity: 1 - _bannerFade.value,
                child: SlideTransition(
                  position: _bannerSlide,
                  child: SafeArea(
                    bottom: false,
                    child: _ScanResultBanner(state: widget.state),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.cutOutSize});
  final double cutOutSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(cutOutSize: cutOutSize),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  const _ScanFab({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              // ignore: deprecated_member_use
              ? MinglitPartnerColors.primary.withOpacity(0.85)
              // ignore: deprecated_member_use
              : Colors.white.withOpacity(0.12),
          border: Border.all(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.18),
          ),
          borderRadius: BorderRadius.circular(MinglitRadius.button),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ScanResultBanner extends StatelessWidget {
  const _ScanResultBanner({required this.state});
  final CheckinState state;

  @override
  Widget build(BuildContext context) {
    final (color, icon, title, subtitle) = _bannerContent(state);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: MinglitSpacing.screenEdge),
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: MinglitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String, String) _bannerContent(CheckinState state) {
    switch (state.result) {
      case CheckinResult.success:
        return (
          MinglitColors.success,
          Icons.check_circle,
          state.userName ?? '체크인 완료',
          state.message ?? '',
        );
      case CheckinResult.alreadyCheckedIn:
        return (
          MinglitColors.warning,
          Icons.info,
          '이미 체크인된 참가자',
          state.message ?? '',
        );
      case CheckinResult.invalid:
      case CheckinResult.error:
        return (
          MinglitColors.error,
          Icons.error,
          '입장 불가',
          state.message ?? '유효하지 않은 QR 코드입니다',
        );
      case CheckinResult.idle:
      case CheckinResult.processing:
        return (Colors.transparent, Icons.info, '', '');
    }
  }
}

/// QR 스캔 프레임 오버레이 shape.
///
/// [cutOutSize]를 반응형으로 외부에서 전달받는다.
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = MinglitColors.background,
    this.borderWidth = 3.0,
    this.overlayColor = MinglitColors.scrim,
    this.borderRadius = 10.0,
    this.borderLength = 30.0,
    this.cutOutSize = 220.0,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions =>
      const EdgeInsets.all(MinglitSpacing.small);

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

    // Corner borders
    for (final path in _cornerPaths(cutOutRect)) {
      canvas.drawPath(path, paint);
    }
  }

  List<Path> _cornerPaths(Rect r) => [
    Path()
      ..moveTo(r.left, r.top + borderLength)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + borderLength, r.top),
    Path()
      ..moveTo(r.right - borderLength, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + borderLength),
    Path()
      ..moveTo(r.right, r.bottom - borderLength)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right - borderLength, r.bottom),
    Path()
      ..moveTo(r.left + borderLength, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.bottom - borderLength),
  ];

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth,
    overlayColor: overlayColor,
    borderRadius: borderRadius,
    borderLength: borderLength,
    cutOutSize: cutOutSize,
  );
}
