import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:app_user/src/features/ticket/logic/boarding_pass_status.dart';
import 'package:app_user/src/features/ticket/ui/model/ticket_event_meta.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:qr_flutter/qr_flutter.dart';

part 'boarding_pass_card_info.dart';
part 'boarding_pass_card_qr.dart';

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (_computeStatus() == BoardingPassStatus.boarding) {
      unawaited(_pulseController.repeat(reverse: true));
    }
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Schedules a one-shot timer that fires at the next local midnight,
  /// triggering a status re-evaluation so BOARDING→USED transition is shown
  /// without the user needing to leave and re-enter the screen.
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);
    _midnightTimer = Timer(durationUntilMidnight, _onMidnight);
  }

  void _onMidnight() {
    if (!mounted) return;
    setState(_updatePulse);
    _scheduleMidnightRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(_updatePulse);
    }
  }

  void _updatePulse() {
    final shouldPulse = _computeStatus() == BoardingPassStatus.boarding;
    if (shouldPulse && !_pulseController.isAnimating) {
      unawaited(_pulseController.repeat(reverse: true));
    } else if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void didUpdateWidget(covariant BoardingPassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePulse();
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
              // ignore: minglit_no_hardcoded_colors -- drop shadow; no equivalent MDS token for pure black
              color: Colors.black.withValues(
                alpha: MinglitOpacity.shadowMd,
              ),
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
