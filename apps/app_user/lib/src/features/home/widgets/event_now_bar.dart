import 'dart:async';

import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Persistent 56px mini-bar at the bottom of HomePage showing the user's
/// active event status (check-in, matching, results, etc.).
///
/// Watches [todayActiveEventsProvider] and displays the first active event.
/// Hidden ([SizedBox.shrink]) when there are no active events.
class EventNowBar extends ConsumerWidget {
  /// Creates an [EventNowBar].
  const EventNowBar({super.key, this.onTap});

  /// Callback when the bar is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(todayActiveEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return _EventNowBarContent(
          activeEvent: events.first,
          onTap: onTap,
        );
      },
      loading: () => const _EventNowBarLoading(),
      error: (_, _) => _buildOfflineBar(context),
    );
  }

  Widget _buildOfflineBar(BuildContext context) {
    return Container(
      height: 56,
      decoration: _barDecoration(),
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
      ),
      child: Center(
        child: Text(
          '(오프라인)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MinglitColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Shared decoration for the 56px bar.
BoxDecoration _barDecoration() {
  return BoxDecoration(
    color: MinglitColors.surface,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(MinglitRadius.card),
      topRight: Radius.circular(MinglitRadius.card),
    ),
    border: Border(
      top: BorderSide(
        color: MinglitColors.primary.withValues(alpha: 0.1),
      ),
    ),
  );
}

/// Internal bar content for a single active event.
///
/// Separated into [ConsumerStatefulWidget] to manage the pulse
/// [AnimationController] lifecycle for the RESULTS state.
class _EventNowBarContent extends ConsumerStatefulWidget {
  const _EventNowBarContent({
    required this.activeEvent,
    this.onTap,
  });

  final TodayActiveEvent activeEvent;
  final VoidCallback? onTap;

  @override
  ConsumerState<_EventNowBarContent> createState() =>
      _EventNowBarContentState();
}

class _EventNowBarContentState extends ConsumerState<_EventNowBarContent>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  void _ensurePulseController() {
    if (_pulseController != null) return;
    _pulseController = AnimationController(
      vsync: this,
      duration: MinglitAnimation.medium,
    );
    unawaited(_pulseController!.repeat(reverse: true));
  }

  void _disposePulseController() {
    _pulseController?.dispose();
    _pulseController = null;
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      eventNowBarStateProvider(widget.activeEvent),
    );

    return stateAsync.when(
      data: (state) => _buildBar(context, state),
      loading: () => const _EventNowBarLoading(),
      // Fix #662: fallback to WAITING on error — keeps bar visible with
      // cached event data instead of hiding it entirely.
      error: (_, _) => _buildBar(context, EventNowBarState.waiting),
    );
  }

  Widget _buildBar(BuildContext context, EventNowBarState state) {
    final event = widget.activeEvent.event;
    final theme = Theme.of(context);
    final dotColor = _dotColor(state);
    final statusLabel = _statusText(state);
    final needsPulse = state == EventNowBarState.results;

    if (needsPulse) {
      _ensurePulseController();
    } else {
      _disposePulseController();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 56,
        decoration: _barDecoration(),
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.screenEdge,
        ),
        child: Row(
          children: [
            // Status dot — 8px circle, color per state
            _buildDot(dotColor, needsPulse),
            const SizedBox(width: MinglitSpacing.sm),
            // Event name — single line, ellipsis
            Flexible(
              child: Text(
                event.title ?? '이벤트',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Status text
            Text(
              statusLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: MinglitColors.textSecondary,
              ),
            ),
            const SizedBox(width: MinglitSpacing.small),
            // Trailing: time for waiting, chevron for others
            _buildTrailing(context, state, event),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color, bool pulse) {
    if (!pulse || _pulseController == null) {
      return _dot(color);
    }

    return AnimatedBuilder(
      animation: _pulseController!,
      builder: (context, child) {
        final opacity = 0.4 + 0.6 * _pulseController!.value;
        return Opacity(opacity: opacity, child: child);
      },
      child: _dot(color),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildTrailing(
    BuildContext context,
    EventNowBarState state,
    Event event,
  ) {
    if (state == EventNowBarState.waiting) {
      final timeUntilStart = event.startTime.difference(DateTime.now());
      final minutes = timeUntilStart.inMinutes;
      final timeText = minutes > 60
          ? '${timeUntilStart.inHours}시간 후'
          : '$minutes분 후';
      return Text(
        timeText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: MinglitColors.textSecondary,
        ),
      );
    }
    return const Icon(
      Icons.chevron_right,
      color: MinglitColors.textSecondary,
      size: MinglitIconSize.small,
    );
  }

  static Color _dotColor(EventNowBarState state) {
    return switch (state) {
      EventNowBarState.waiting => MinglitColors.textSecondary,
      EventNowBarState.checkInReady => MinglitColors.primary,
      EventNowBarState.checkedIn => MinglitColors.success,
      EventNowBarState.matching => MinglitColors.secondary,
      EventNowBarState.results => MinglitColors.primary,
      EventNowBarState.ended => MinglitColors.textSecondary,
    };
  }

  static String _statusText(EventNowBarState state) {
    return switch (state) {
      EventNowBarState.waiting => '곧 시작',
      EventNowBarState.checkInReady => '체크인하세요',
      EventNowBarState.checkedIn => '체크인 완료',
      EventNowBarState.matching => '매칭 진행 중',
      EventNowBarState.results => '결과 확인',
      EventNowBarState.ended => '종료됨',
    };
  }
}

/// Skeleton loading placeholder matching the 56px bar height.
class _EventNowBarLoading extends StatelessWidget {
  const _EventNowBarLoading();

  @override
  Widget build(BuildContext context) {
    return const MinglitSkeleton(
      height: 56,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(MinglitRadius.card),
        topRight: Radius.circular(MinglitRadius.card),
      ),
    );
  }
}
