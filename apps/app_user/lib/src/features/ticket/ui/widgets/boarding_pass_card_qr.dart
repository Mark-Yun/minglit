part of 'boarding_pass_card.dart';

// ---------------------------------------------------------------------------
// Section 3: Perforation Line
// ---------------------------------------------------------------------------

/// Airline-ticket perforation line — the key detail that makes it feel like
/// a real physical ticket.
/// Renders a dashed line with semicircle notches at the card left/right edges.
// Fix #1526: PerforationPainter — "진짜 티켓" 느낌의 핵심 디테일
class _PerforationLine extends StatelessWidget {
  const _PerforationLine();

  static const double _notchDiameter = 28;
  static const double _notchRadius = _notchDiameter / 2;

  @override
  Widget build(BuildContext context) {
    // Fix #1931: use theme-aware color so dash line is visible in dark mode
    final dashColor = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      color: MinglitColors.background,
      height: _notchDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dashed center line (excludes the notch areas)
          Positioned.fill(
            child: CustomPaint(
              painter: _DashLinePainter(
                notchRadius: _notchRadius,
                dashColor: dashColor,
              ),
            ),
          ),
          // Left notch — positioned to overlap card left edge
          Positioned(
            left: -_notchRadius,
            top: 0,
            child: _NotchCircle(size: _notchDiameter),
          ),
          // Right notch — positioned to overlap card right edge
          Positioned(
            right: -_notchRadius,
            top: 0,
            child: _NotchCircle(size: _notchDiameter),
          ),
        ],
      ),
    );
  }
}

/// Solid circle matching page background — creates the "cutout" illusion.
class _NotchCircle extends StatelessWidget {
  const _NotchCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Fix #1931: match scaffold background so dark mode doesn't show white circles
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Draws a horizontal dashed line, skipping the notch areas at each end.
class _DashLinePainter extends CustomPainter {
  const _DashLinePainter({
    required this.notchRadius,
    required this.dashColor,
  });

  final double notchRadius;
  final Color dashColor;

  static const double _dashWidth = 6;
  static const double _dashGap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dashColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final y = size.height / 2;
    final startX = notchRadius;
    final endX = size.width - notchRadius;

    var x = startX;
    while (x < endX) {
      final segmentEnd = math.min(x + _dashWidth, endX);
      canvas.drawLine(Offset(x, y), Offset(segmentEnd, y), paint);
      x += _dashWidth + _dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashLinePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Section 4: QR Stub
// ---------------------------------------------------------------------------

/// QR stub section — omagio of the barcode area on airline boarding passes.
/// Contains: QR code (with scanning animation), ticket number, status badge.
class _QRStubSection extends StatelessWidget {
  const _QRStubSection({
    required this.token,
    required this.status,
    required this.scanningAnimation,
    required this.pulseAnimation,
  });

  final TicketToken token;
  final BoardingPassStatus status;
  final AnimationController scanningAnimation;
  final AnimationController pulseAnimation;

  static const _qrSize = 200.0;

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode(token.toJson());
    final isUsed = status == BoardingPassStatus.used;

    return Container(
      color: MinglitColors.background,
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.medium,
        MinglitSpacing.large,
        MinglitSpacing.large,
      ),
      child: Column(
        children: [
          // QR + scanning line overlay
          Center(
            child: SizedBox(
              width: _qrSize,
              height: _qrSize,
              child: Stack(
                children: [
                  // QR code
                  Semantics(
                    label: '이벤트 입장 QR 코드',
                    child: QrImageView(
                      data: qrData,
                      size: _qrSize,
                      gapless: false,
                    ),
                  ),
                  // Scanning line (disabled for USED)
                  if (!isUsed)
                    AnimatedBuilder(
                      key: const ValueKey('scanning-line'),
                      animation: scanningAnimation,
                      builder: (context, _) {
                        return Positioned(
                          top: _qrSize * scanningAnimation.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: MinglitColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: MinglitColors.primary.withValues(
                                    alpha: MinglitOpacity.strong,
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
            ),
          ),

          const SizedBox(height: MinglitSpacing.medium),

          // TICKET NO. / STATUS row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: ticket number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _MetaLabel('TICKET NO.'),
                  const SizedBox(height: 2),
                  Text(
                    _formatTicketNo(token.ticketId),
                    style: const TextStyle(
                      color: MinglitColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Right: status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _MetaLabel('STATUS'),
                  const SizedBox(height: 2),
                  _StatusBadge(
                    status: status,
                    pulseAnimation: pulseAnimation,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Formats ticketId as "#TK-XXXX" (8-char hex prefix).
  static String _formatTicketNo(String ticketId) {
    final prefix = ticketId.length > 8
        ? ticketId.substring(0, 8).toUpperCase()
        : ticketId.toUpperCase();
    return '#TK-$prefix';
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: MinglitColors.textSecondary,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

/// Status badge with three visual states: BOARDING (green pulse), CONFIRMED
/// (primary), USED (gray).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.pulseAnimation,
  });

  final BoardingPassStatus status;
  final AnimationController pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      BoardingPassStatus.boarding => _boardingBadge(),
      BoardingPassStatus.confirmed => const Text(
        'CONFIRMED',
        style: TextStyle(
          color: MinglitColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      BoardingPassStatus.used => const Text(
        'USED',
        style: TextStyle(
          color: MinglitColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    };
  }

  Widget _boardingBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, _) {
            return Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: MinglitColors.success.withValues(
                  alpha: 0.4 + 0.6 * pulseAnimation.value,
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        const Text(
          'BOARDING',
          style: TextStyle(
            color: MinglitColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
