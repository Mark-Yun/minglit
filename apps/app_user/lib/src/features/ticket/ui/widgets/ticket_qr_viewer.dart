import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// **Ticket QR Viewer**
///
/// Renders a signed [TicketToken] as a QR code with a scanning animation line.
/// Automatically handles screen brightness for better scanability.
class TicketQRViewer extends StatefulWidget {
  const TicketQRViewer({required this.token, super.key});

  final TicketToken token;

  @override
  State<TicketQRViewer> createState() => _TicketQRViewerState();
}

class _TicketQRViewerState extends State<TicketQRViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double? _originalBrightness;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_animationController.repeat(reverse: true));

    unawaited(_maximizeBrightness());
  }

  @override
  void dispose() {
    _animationController.dispose();
    unawaited(_restoreBrightness());
    super.dispose();
  }

  Future<void> _maximizeBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().application;
      await ScreenBrightness().setApplicationScreenBrightness(1);
    } on Object catch (e) {
      Log.e('Failed to set screen brightness', e);
    }
  }

  Future<void> _restoreBrightness() async {
    if (_originalBrightness != null) {
      try {
        await ScreenBrightness().setApplicationScreenBrightness(
          _originalBrightness!,
        );
      } on Object catch (e) {
        Log.e('Failed to restore screen brightness', e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = jsonEncode(widget.token.toJson());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 1. QR Code
            Container(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                size: 240,
                gapless: false,
              ),
            ),

            // 2. Scanning Line Animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  top: 20 + (240 * _animationController.value),
                  child: Container(
                    width: 220,
                    height: 2,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text(
          '입장 시 파트너에게 이 화면을 보여주세요',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
