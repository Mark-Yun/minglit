import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:app_user/src/features/ticket/logic/boarding_pass_status.dart';
import 'package:app_user/src/features/ticket/ui/model/ticket_event_meta.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Fix #1526: BoardingPassCard — 항공 보딩패스 메타포 적용 (4영역 카드 구조)

/// **BoardingPassCard**
///
/// Displays a ticket as an airline boarding pass.
/// 4-section layout: brand header → event info → perforation → QR stub.
///
/// [token] provides QR payload. [eventMeta] provides display context.
/// When [eventMeta] is null, placeholder dashes are shown (graceful
/// degradation).
class BoardingPassCard extends StatefulWidget {
  const BoardingPassCard({
    required this.token,
    required this.scanningAnimation,
    this.eventMeta,
    super.key,
  });

  final TicketToken token;

  /// Event metadata for display. Optional to support deep-link callers
  /// that do not yet pass metadata.
  final TicketEventMeta? eventMeta;

  /// External [AnimationController] driving the scanning line.
  /// Should be a repeating controller with `reverse: true`.
  final AnimationController scanningAnimation;

  @override
  State<BoardingPassCard> createState() => _BoardingPassCardState();
}

class _BoardingPassCardState extends State<BoardingPassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (_computeStatus() == BoardingPassStatus.boarding) {
      unawaited(_pulseController.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BoardingPassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPulse = _computeStatus() == BoardingPassStatus.boarding;
    if (shouldPulse && !_pulseController.isAnimating) {
      unawaited(_pulseController.repeat(reverse: true));
    } else if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  BoardingPassStatus _computeStatus() {
    final meta = widget.eventMeta;
    if (meta == null) return BoardingPassStatus.confirmed;
    return boardingPassStatus(meta.eventDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final status = _computeStatus();
    final isUsed = status == BoardingPassStatus.used;

    return Opacity(
      opacity: isUsed ? MinglitOpacity.overlay : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: MinglitOpacity.shadowMd),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _HeaderStrip(),
              _EventInfoSection(eventMeta: widget.eventMeta),
              const _PerforationLine(),
              _QRStubSection(
                token: widget.token,
                status: status,
                scanningAnimation: widget.scanningAnimation,
                pulseAnimation: _pulseController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1: Header Strip
// ---------------------------------------------------------------------------

/// Brand header strip — omagio of airline top bar.
/// Gradient background, Minglit logo (white) on left, "BOARDING PASS" on right.
class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MinglitColors.primary, MinglitColors.primaryDark],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.large,
      ),
      child: Row(
        children: [
          // White logo — ColorFiltered wraps the themed SVG
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              MinglitColors.background,
              BlendMode.srcIn,
            ),
            child: MinglitTheme.appBarLogo(height: 24),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'BOARDING PASS',
                style: TextStyle(
                  color: MinglitColors.background,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '입장권',
                style: TextStyle(
                  color: MinglitColors.background.withValues(
                    alpha: MinglitOpacity.scrimDark,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2: Event Info
// ---------------------------------------------------------------------------

/// Event info section — omagio of airline FROM/TO flight info zone.
/// DATE (left) → arrow → VENUE (right), then event title and ticket type.
class _EventInfoSection extends StatelessWidget {
  const _EventInfoSection({this.eventMeta});

  final TicketEventMeta? eventMeta;

  @override
  Widget build(BuildContext context) {
    final meta = eventMeta;
    final dateLabel = meta != null
        ? DateFormat('M월 d일 (E)', 'ko_KR').format(meta.eventDateTime)
        : '—';
    final timeLabel = meta != null
        ? DateFormat('HH:mm').format(meta.eventDateTime)
        : '—';
    final venueLabel = meta?.eventVenue ?? '—';
    final eventTitle = meta?.eventTitle ?? '—';
    final ticketName = meta?.ticketName;

    return Container(
      color: MinglitColors.background,
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.medium,
        MinglitSpacing.large,
        MinglitSpacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flight-style info row: DATE → VENUE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: DATE section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('DATE'),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: MinglitColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: MinglitColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              // Center: arrow aligned to time row
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text(
                  '→',
                  style: TextStyle(
                    color: MinglitColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ),
              // Right: VENUE section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const _FieldLabel('VENUE', rightAligned: true),
                    const SizedBox(height: 2),
                    Text(
                      venueLabel,
                      style: const TextStyle(
                        color: MinglitColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: MinglitSpacing.sm),
            child: Divider(height: 1, color: MinglitColors.surface),
          ),

          // Event title (center aligned, 2-line ellipsis)
          Text(
            eventTitle,
            style: const TextStyle(
              color: MinglitColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Ticket type (optional)
          if (ticketName != null) ...[
            const SizedBox(height: MinglitSpacing.xsmall),
            Text(
              'TICKET · $ticketName',
              style: const TextStyle(
                color: MinglitColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.rightAligned = false});

  final String text;
  final bool rightAligned;

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
      textAlign: rightAligned ? TextAlign.right : TextAlign.left,
    );
  }
}

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
    return Container(
      color: MinglitColors.background,
      height: _notchDiameter,
      child: const Stack(
        clipBehavior: Clip.none,
        children: [
          // Dashed center line (excludes the notch areas)
          Positioned.fill(
            child: CustomPaint(
              painter: _DashLinePainter(
                notchRadius: _notchRadius,
                dashColor: MinglitColors.divider,
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

/// Solid circle in scaffold surface color — creates the "cutout" illusion.
class _NotchCircle extends StatelessWidget {
  const _NotchCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: MinglitColors.surface,
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
